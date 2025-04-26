import os
import time
import torch
import torch.nn as nn
import torch.optim as optim
import random

# --- Hyperparameters
INPUT_SIZE = 4
OUTPUT_SIZE = 4
HIDDEN = 64
BATCH_SIZE = 32
MEMORY_SIZE = 10000
GAMMA = 0.99
LR = 0.0005
TARGET_UPDATE_FREQ = 100
EPSILON_DECAY = 0.9998
EPSILON_MIN = 0.05

INPUT_PATH = "inputs.txt"
OUTPUT_PATH = "outputs.txt"

# --- Q-Network
class QNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.model = nn.Sequential(
            nn.Linear(INPUT_SIZE, HIDDEN),
            nn.ReLU(),
            nn.Linear(HIDDEN, HIDDEN),
            nn.ReLU(),
            nn.Linear(HIDDEN, OUTPUT_SIZE)
        )

    def forward(self, x):
        return self.model(x)

# --- Replay Memory
class ReplayMemory:
    def __init__(self):
        self.memory = []

    def push(self, s, a, r, s_):
        self.memory.append((s, a, r, s_))
        if len(self.memory) > MEMORY_SIZE:
            self.memory.pop(0)

    def sample(self):
        return random.sample(self.memory, min(BATCH_SIZE, len(self.memory)))

# --- Agent
class DQNAgent:
    def __init__(self):
        self.qnet = QNet()
        self.target = QNet()
        self.target.load_state_dict(self.qnet.state_dict())
        self.optimizer = optim.Adam(self.qnet.parameters(), lr=LR)
        self.memory = ReplayMemory()
        self.steps = 0
        self.epsilon = 1.0

    def act(self, state):
        if random.random() < self.epsilon:
            return random.randint(0, OUTPUT_SIZE - 1)
        with torch.no_grad():
            state_tensor = torch.tensor(state, dtype=torch.float32)
            qvals = self.qnet(state_tensor)
            return int(torch.argmax(qvals).item())

    def remember(self, s, a, r, s_):
        self.memory.push(s, a, r, s_)

    def train(self):
        batch = self.memory.sample()
        if len(batch) < BATCH_SIZE:
            return

        states, actions, rewards, next_states = zip(*batch)

        states = torch.tensor(states, dtype=torch.float32)
        actions = torch.tensor(actions, dtype=torch.long)
        rewards = torch.tensor(rewards, dtype=torch.float32)
        next_states = torch.tensor(next_states, dtype=torch.float32)

        q_values = self.qnet(states).gather(1, actions.unsqueeze(1)).squeeze(1)
        next_q_values = self.target(next_states).max(1)[0]
        target_q = rewards + GAMMA * next_q_values

        loss = nn.MSELoss()(q_values, target_q)
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        self.steps += 1
        if self.steps % TARGET_UPDATE_FREQ == 0:
            self.target.load_state_dict(self.qnet.state_dict())

        self.epsilon = max(EPSILON_MIN, self.epsilon * EPSILON_DECAY)

# --- File polling
agent = DQNAgent()

print("Waiting for inputs.txt...")
last_input = ""
state = [0.0] * INPUT_SIZE
prev_state = None
prev_action = None

while True:
    if not os.path.exists(INPUT_PATH):
        time.sleep(0.01)
        continue

    with open(INPUT_PATH, "r") as f:
        content = f.read().strip()

    if content == last_input or not content:
        time.sleep(0.005)
        continue

    last_input = content
    state = [float(x.strip()) for x in content.split(",") if x.strip()]

    action = agent.act(state)
    action_str = ["Left", "Right", "Up", "Down"][action]

    with open(OUTPUT_PATH, "w") as f:
        f.write(action_str)

    if prev_state is not None:
        reward_file = "reward.txt"
        if os.path.exists(reward_file):
            with open(reward_file, "r") as f:
                try:
                    reward = float(f.read().strip())
                    agent.remember(prev_state, prev_action, reward, state)
                    agent.train()
                except:
                    pass

    prev_state = state
    prev_action = action
    time.sleep(0.005)  # small delay for stability