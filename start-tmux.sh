#!/bin/bash

session=$1

# Check if the session exists
tmux has-session -t $session 2>/dev/null

if [ $? != 0 ]; then
    tmux new-session -d -s $session
    tmux split-window -t "$session:1.1" -h
    tmux split-window -t "$session:1.2" -v

    tmux resize-pane -t "$session:1.1" -x 55

    tmux send-keys -t "$sesson:1.1" "conda activate $session && sprompt" C-m
    tmux send-keys -t "$sesson:1.1" C-l

    tmux send-keys -t "$sesson:1.2" "conda activate $session && sprompt" C-m
    tmux send-keys -t "$sesson:1.2" C-l

    tmux send-keys -t "$sesson:1.3" "conda activate $session && sprompt" C-m
    tmux send-keys -t "$sesson:1.3" C-l

    tmux send-keys -t "$sesson:1.1" "vim" C-m
    tmux select-pane -t "$sesson:1.1"
fi

tmux a -t $session

