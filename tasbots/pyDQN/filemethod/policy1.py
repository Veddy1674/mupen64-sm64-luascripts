import torch
import torch.nn as nn
import torch.optim as optim
import random
import os

inputcount = 5
modelpath = "tasbots\\pyDQN\\filemethod\\model.pth"

valid_actions = [
    [0,0,0,0],  # nessun tasto
    [0,0,0,1],  # right
    [0,0,1,0],  # left
    [0,1,0,0],  # down
    [0,1,0,1],  # down+right
    [0,1,1,0],  # down+left
    [1,0,0,0],  # up
    [1,0,0,1],  # up+right
    [1,0,1,0],  # up+left
]

def action_to_index(action):
    for i, a in enumerate(valid_actions):
        if a == action:
            return i
    raise ValueError("Invalid action: " + str(action))

def index_to_action(idx):
    return valid_actions[idx]

class SimpleDQN(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(inputcount, 32),
            nn.ReLU(),
            nn.Linear(32, 9)
        )

    def forward(self, x):
        return self.net(x)

class AI:
    def __init__(self):
        self.model = SimpleDQN()
        self.optimizer = optim.Adam(self.model.parameters(), lr=0.001)
        self.loss_fn = nn.MSELoss()
        self.transitions = []
        self.last_state = [0.0] * inputcount
        self.last_entry = None

        if os.path.exists(modelpath):
            print("Loaded AI model with data!")
            self.model.load_state_dict(torch.load(modelpath))
        else:
            print("Loaded AI model for the first time!")

    def add_data(self, line):
        parts = line.strip().split(",")
        
        reward = float(parts[0])
        action = list(map(int, parts[1:5])) # never changes
        
        state_strs = parts[5:-1]
        state = list(map(float, state_strs))
        
        done = parts[-1] == "1"
        
        try:
            action_idx = action_to_index(action)
        except ValueError:
            # azione non valida, scarta
            return

        if self.last_entry is not None:
            prev_state, prev_action, prev_reward = self.last_entry
            self.transitions.append((prev_state, prev_action, prev_reward, state, done))

        self.last_entry = (state, action, reward)
        self.last_state = state

    def train(self, batch_size=16, gamma=0.99, save=False):
        if len(self.transitions) < batch_size:
            return
        batch = random.sample(self.transitions, batch_size)
        
        for state, action, reward, next_state, done in batch:
            try:
                action_idx = action_to_index(action)
            except ValueError:
                # skip azioni invalide
                continue
            
            s = torch.tensor(state, dtype=torch.float32)
            q = self.model(s)
            target = q.clone().detach()

            if done:
                q_target = reward
            else:
                next_q = self.model(torch.tensor(next_state, dtype=torch.float32))
                q_target = reward + gamma * torch.max(next_q).item()
            
            target[action_idx] = q_target

            loss = self.loss_fn(q, target)
            self.optimizer.zero_grad()
            loss.backward()
            self.optimizer.step()
        
        if save:
            torch.save(self.model.state_dict(), modelpath)

    def choose_action(self, epsilon=0.1):
        if random.random() < epsilon:
            best = random.randint(0, len(valid_actions)-1)
        else:
            s = torch.tensor(self.last_state, dtype=torch.float32)
            with torch.no_grad():
                q = self.model(s)
            best = torch.argmax(q).item()
        
        action = index_to_action(best)
        return ",".join(str(x) for x in action)