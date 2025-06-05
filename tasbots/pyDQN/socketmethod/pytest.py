import socket

HOST = "localhost"
PORT = 50001

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((HOST, PORT))
server.listen(1)
print("Waiting for lua...")

conn, addr = server.accept()
print("Lua connected:", addr)

try:
    while True:
        data = conn.recv(1024)
        if not data:
            break

        message = data.decode()
        print("Received:", message)
        
        if message == "LuaReady":
            response = "PythonReady"

        conn.sendall(response.encode())

except KeyboardInterrupt:
    print("Server closed.")

conn.close()
server.close()
print("Communication end.")