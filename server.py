import threading
import socket
import sys
import tkinter as tk

# Create the main UI
window = tk.Tk()
window.title("Messaging Client")

# Create a text widget to display the chat history
chat_history = tk.Text()
chat_history.pack()

# Create a function to update the chat history
def update_chat_history(message):
    chat_history.insert('end', message + '\n')

# Create a function to send messages to the server
def send_messages():
    while True:
        # Get the message from the text entry
        message = message_entry.get()

        # If the message is not empty, send it to the server
        if message:
            # Send the message to the server
            server_socket.send(message.encode())

            # Clear the message entry
            message_entry.delete(0, 'end')

            # Update the chat history
            update_chat_history('Client: ' + message)

# Create a function to receive messages from the server
def receive_messages():
    while True:
        # Receive data from the server
        data = server_socket.recv(1024)

        # If no data was received, the server has disconnected
        if not data:
            # Update the chat history to show that the server has disconnected
            update_chat_history('Server has disconnected')

            # Close the server socket
            server_socket.close()
            break

        # Decode the received data and print it
        message = data.decode()
        print(message)

        # Update the chat history
        update_chat_history('Server: ' + message)

# Create a function to run the client socket
def run_client():
    global server_socket

    # Create the client socket
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Connect the client socket to the server
    server_socket.connect(('localhost', 14242))

    # Update the chat history to show that a connection has been established
    update_chat_history('Connection established with server')

    # Create and start the send and receive threads
    send_thread = threading.Thread(target=send_messages)
    receive_thread = threading.Thread(target=receive_messages)
    send_thread.start()
    receive_thread.start()

# Create a text entry and button to send messages
message_entry = tk.Entry()
message_entry.pack()
send_button = tk.Button(text="Send", command=send_messages)
send_button.pack()

# Run the client socket
run_client()

# Start the main UI event loop
window.mainloop()

# Close the server socket
server_socket.close()
