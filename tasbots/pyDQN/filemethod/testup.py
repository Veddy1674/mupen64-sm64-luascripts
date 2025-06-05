import time

input_path = "tasbots\\pyDQN\\filemethod\\input.txt"
output_path = "tasbots\\pyDQN\\filemethod\\output.txt"

print("Python listening...")

last_position = 0

while True:
    open(output_path, "w").close()
    with open(input_path, "r") as f:
        f.seek(last_position)
        line = f.readline()
        
        if line:
            actionToDo = "1,0,0,0"
            line = line.strip()
            print("Content received, responded with: ", actionToDo)
            last_position = f.tell()
            
            with open(output_path, "w") as out:
                out.write(actionToDo)
    
    time.sleep(0.05)