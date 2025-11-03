import socket
import sys
import time

def connect_to_server(host='localhost', port=12345, timeout=10):
    try:
        # Create socket
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.settimeout(timeout)
        
        # Connect to server
        print(f"🔌 Connecting to {host}:{port}...")
        client_socket.connect((host, port))
        print("✅ Connected successfully!")
        return client_socket
    
    except socket.timeout:
        print("❌ Connection timed out")
        sys.exit(1)
    except ConnectionRefusedError:
        print("❌ Server is not running")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Connection failed: {str(e)}")
        sys.exit(1)

def send_receive_message(client_socket, message):
    try:
        # Send data
        print(f"📤 Sending: {message}")
        client_socket.sendall(message.encode())
        
        # Receive response
        response = client_socket.recv(1024)
        if response:
            print(f"📩 Received: {response.decode()}")
        else:
            print("⚠️ No response from server")
            
    except Exception as e:
        print(f"❌ Communication error: {str(e)}")
        
def main():
    client_socket = None
    try:
        client_socket = connect_to_server()
        
        # Main communication loop
        while True:
            message = input("Enter message (or 'quit' to exit): ")
            if message.lower() == 'quit':
                break
                
            send_receive_message(client_socket, message)
            
    except KeyboardInterrupt:
        print("\n⚠️ Program interrupted by user")
        
    finally:
        if client_socket:
            print("👋 Closing connection...")
            client_socket.close()

if __name__ == "__main__":
    main()