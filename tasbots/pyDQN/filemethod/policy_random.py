import random

def get_action():
    r = random.random()
    if r < 0.25:
        return "1,0,0,0"  # UP
    elif r < 0.5:
        return "0,0,0,1"  # RIGHT
    elif r < 0.75:
        return "0,0,1,0"  # LEFT
    else:
        return "0,1,0,0"  # DOWN