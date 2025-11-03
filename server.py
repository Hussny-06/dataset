import socket
import sys
from datetime import datetime

def create_server(host='localhost', port=12345):
    try:
        # Create socket
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
        # Allow port reuse
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # Bind to IP and port
        server_socket.bind((host, port))
        return server_socket
    
    except Exception as e:
        print(f"❌ Failed to create server: {str(e)}")
        sys.exit(1)

def handle_client(conn, addr):
    try:
        print(f"🔗 New connection from {addr}")
        
        while True:
            # Receive data
            data = conn.recv(1024)
            if not data:
                break
                
            # Log received message with timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            message = data.decode()
            print(f"[{timestamp}] 📩 Received from {addr}: {message}")
            
            # Process message and send response
            response = f"Server received: {message}"
            conn.sendall(response.encode())
            
    except ConnectionResetError:
        print(f"⚠️ Client {addr} disconnected unexpectedly")
    except Exception as e:
        print(f"❌ Error handling client {addr}: {str(e)}")
    finally:
        conn.close()
        print(f"👋 Connection closed with {addr}")

def main():
    server_socket = None
    try:
        server_socket = create_server()
        
        # Start listening
        server_socket.listen(5)  # Allow up to 5 pending connections
        print("✅ Server is listening on port 12345...")
        
        # Main server loop
        while True:
            try:
                # Accept connection
                conn, addr = server_socket.accept()
                handle_client(conn, addr)
            except KeyboardInterrupt:
                print("\n⚠️ Server shutdown initiated...")
                break
                
    except Exception as e:
        print(f"❌ Server error: {str(e)}")
        
    finally:
        if server_socket:
            server_socket.close()
            print("👋 Server shutdown complete")

if __name__ == "__main__":
    main()