try:
    print("Loading AI model...")

    import time
    from policy1 import AI

    ai = AI()
    print("Waiting for lua...")

    input_path = "tasbots\\pyDQN\\filemethod\\input.txt"
    output_path = "tasbots\\pyDQN\\filemethod\\output.txt"
    info_path = "tasbots\\pyDQN\\filemethod\\info.csv"

    last_position = 0
    open(input_path, "w").close()
    open(output_path, "w").close()
    open(info_path, "w").close()
    
    epsilon = 1.0
    epsilon_min = 0.1
    epsilon_decay = 0.998

    step, stepGoal = 0, 1
    while True:
        
        with open(input_path, "r") as f:
            f.seek(last_position)
            line = f.readline()
            
            if line:
                line = line.strip()
                ai.add_data(line)
                step += 1
                if step % stepGoal == 0:
                    ai.train(batch_size=32, gamma=0.99, save=(step % 100 == 0))
                    print("AI Trained (" + str(step) + " steps), epsilon: " + str(epsilon))
                
                action = ai.choose_action(epsilon=epsilon)
                epsilon = max(epsilon_min, epsilon * epsilon_decay)
                
                last_position = f.tell()
                with open(output_path, "w") as out:
                    out.write(action)
        
        time.sleep(0.05)

except KeyboardInterrupt:
    print("Exiting...")