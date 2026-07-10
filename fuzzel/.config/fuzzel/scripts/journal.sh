#!/bin/bash

fuzzel --dmenu --lines=0 --prompt="Note: " | hey journal write
