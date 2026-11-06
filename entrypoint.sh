#!/bin/sh
exec /opt/venv/bin/python /app/Tautulli.py --nolaunch --datadir /config --config /config/config.ini "$@"
