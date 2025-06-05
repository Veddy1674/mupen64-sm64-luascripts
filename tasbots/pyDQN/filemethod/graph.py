import matplotlib.pyplot as plt

filename = "tasbots\\pyDQN\\filemethod\\info.csv"
episodes = []
avg_rewards = []
surviveds = []

with open(filename, 'r') as file:
    for line in file:
        parts = line.strip().split(',')
        
        try:
            episode = int(parts[0].split(':')[1])
            avg_reward = float(parts[1].split(':')[1])
            survived = int(parts[2].split(':')[1])
            
            episodes.append(episode)
            avg_rewards.append(avg_reward)
            surviveds.append(survived)
        except (ValueError, IndexError):
            continue

if avg_rewards:
    print(f"Episode count: {len(avg_rewards)}")
    print(f"Max avg reward: {max(avg_rewards):.2f}")
    print(f"Min avg reward: {min(avg_rewards):.2f}")
    print(f"Lowest frame count: {min(surviveds)}")
else:
    print("No data found.")

plt.figure(figsize=(10, 5))
plt.plot(episodes, avg_rewards, label='Avg Reward', color='blue')
plt.plot(episodes, surviveds, label='Lifetime', color='orange')
plt.title('Average Reward per Episode')
plt.xlabel('Episode')
plt.ylabel('Avg Reward')
plt.grid(True)
plt.legend()
plt.show()