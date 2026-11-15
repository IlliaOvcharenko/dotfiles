-- Terminal setup migration from tmux and iTerm2.
-- Keep Rex defaults, including cmd+k for the session picker.
-- iTerm2 has no custom key mappings or configured hotkey to migrate.
-- The tmux clipboard bridge, targeted pane swaps, layouts, and options
-- have no equivalent Rex actions; no approximate bindings are installed.

-- Label the focused pane for editor/runner workflows without moving focus.
rex.action{
    name = "label_pane",
    title = "Label Pane",
    args = { label = "string" },
    run = function(ctx, args)
        if not ctx.block_id then
            error("No focused pane to label", 0)
        end
        local _, err = rex.session.set_block_label{
            block_id = ctx.block_id,
            label = args.label,
        }
        if err ~= nil then error(err, 0) end
    end,
}

-- Number tiled panes clockwise around each outer edge, then work inward.
-- Each rectangle is in window coordinates; floating panes are not numbered.
local function clockwise_panes(layout)
    local remaining, ordered = {}, {}
    local function collect(node)
        if not node then return end
        if node.block_id then
            local r = node.rect
            remaining[#remaining + 1] = {
                id = node.block_id, x = r[1], y = r[2],
                right = r[1] + r[3], bottom = r[2] + r[4],
            }
        elseif node.split then
            collect(node.split.before)
            collect(node.split.after)
        end
    end
    collect(layout)

    local epsilon = 0.000000001
    while #remaining > 0 do
        local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
        for _, pane in ipairs(remaining) do
            left = math.min(left, pane.x)
            top = math.min(top, pane.y)
            right = math.max(right, pane.right)
            bottom = math.max(bottom, pane.bottom)
        end
        local ring, inner = {}, {}
        for _, pane in ipairs(remaining) do
            -- Assign corner panes only once: top, right, bottom, then left.
            if math.abs(pane.y - top) < epsilon then
                pane.side, pane.position = 1, pane.x
            elseif math.abs(pane.right - right) < epsilon then
                pane.side, pane.position = 2, pane.y
            elseif math.abs(pane.bottom - bottom) < epsilon then
                pane.side, pane.position = 3, -pane.right
            elseif math.abs(pane.x - left) < epsilon then
                pane.side, pane.position = 4, -pane.bottom
            else
                pane.side = nil
            end
            if pane.side then
                ring[#ring + 1] = pane
            else
                inner[#inner + 1] = pane
            end
        end
        table.sort(ring, function(a, b)
            if a.side ~= b.side then return a.side < b.side end
            if a.position ~= b.position then return a.position < b.position end
            return a.id < b.id
        end)
        for _, pane in ipairs(ring) do ordered[#ordered + 1] = pane.id end
        remaining = inner
    end
    return ordered
end

rex.action{
    name = "focus_clockwise_pane",
    title = "Focus Clockwise Pane",
    args = { index = "integer" },
    run = function(ctx, args)
        if args.index < 1 or args.index > 10 then
            error("Pane index must be from 1 to 10", 0)
        end
        local view, err = rex.session.view{ session_id = ctx.session_id }
        if err ~= nil then error(err, 0) end
        for _, window in ipairs(view.windows or {}) do
            if window.window_id == view.active_window_id then
                for _, layer in ipairs(window.layers or {}) do
                    if layer.kind == "tiled" then
                        local panes = clockwise_panes(layer.layout)
                        local block_id = panes[args.index]
                        -- A number beyond the current pane count does nothing.
                        if not block_id then return end
                        local _, focus_err = rex.session.focus_block{
                            session_id = ctx.session_id,
                            block_id = block_id,
                        }
                        if focus_err ~= nil then error(focus_err, 0) end
                        return
                    end
                end
                return
            end
        end
    end,
}

-- ctrl+b, q, 1..9 selects a pane; 0 selects pane 10.
for index = 1, 10 do
    local key = index == 10 and "0" or tostring(index)
    rex.bind("ctrl+b>q>" .. key, "focus_clockwise_pane", { index = index })
end

-- tmux-style prefix shortcuts (press ctrl+b, then the next key).
rex.bind("ctrl+b>r", "label_pane", { label = "runner" })
rex.bind("ctrl+b>e", "label_pane", { label = "editor" })
rex.bind("ctrl+b>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+b>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+b>1", "client.tab.goto", { index = 1 })
rex.bind("ctrl+b>2", "client.tab.goto", { index = 2 })
rex.bind("ctrl+b>3", "client.tab.goto", { index = 3 })
rex.bind("ctrl+b>4", "client.tab.goto", { index = 4 })
rex.bind("ctrl+b>5", "client.tab.goto", { index = 5 })
rex.bind("ctrl+b>6", "client.tab.goto", { index = 6 })
rex.bind("ctrl+b>7", "client.tab.goto", { index = 7 })
rex.bind("ctrl+b>8", "client.tab.goto", { index = 8 })
rex.bind("ctrl+b>9", "client.tab.goto", { index = 9 })
rex.bind("ctrl+b>s", "session.switch")
rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>shift+;", "client.palette.toggle")
rex.bind("ctrl+b>left", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>right", "pane.focus", { direction = "right" })
rex.bind("ctrl+b>up", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>down", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>o", "pane.focus_next")
rex.bind("ctrl+b>z", "pane.zoom")
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

-- tmux-style scroll mode. Rex scrolls by pages, not individual lines.
-- Exclusive mode prevents accidental typing into the terminal.
rex.mode("scroll", { exclusive = true })
rex.bind("ctrl+b>[", "client.mode.enter", { name = "scroll" })
rex.bind("scroll/k", "client.scroll.page_up")
rex.bind("scroll/j", "client.scroll.page_down")
rex.bind("scroll/enter", "client.mode.exit")
