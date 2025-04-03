# Networked Producer and Consumer

## Prerequisites
Ensure the following are installed:
- **(Ubuntu) WSL Terminal**

- **Ruby 3.0+**
    
    Check Ruby version:
    ```sh
    ruby -v
    ```

- **Bundler**

    Install Bundler:
    ```sh
    gem install bundler             # Installation in Ubuntu terminal
    ```

- **Network Access**
    
    Ensure network access to the consumer machine's port.

## Setup Instructions 
### ***Producer Setup***
1. Clone the repository or download the Zip file.
    ```sh
    git clone https://github.com/kndonetm/stdiscm-p3-producer.git
    ```

2. In a **(Ubuntu) WSL terminal**, navigate into the project.
    ```sh
    cd stdiscm-p3-producer
    ```

3. Install the dependencies.
    ```sh
    bundle install
    ```

4. Set up the configuration by copying the `.env.example` template:
    ```sh
    cp .env.example .env
    ```
    
    Edit the `.env` with required variables:
    ```ini
    NUM_PRODUCER_THREADS=4        # Adjust the number of producer threads as needed
    HOSTNAME=localhost            # Set the appropriate hostname
    PORT=3000                     # Set the port for communication
    VIDEO_DIRECTORIES=/path/to/videos  # Set video directories
    ```

5. Create storage directory for videos
    ```sh
    mkdir -p uploaded_videos        # Creating file directory for uploaded videos
    chmod 775 uploaded_videos       # Setting up permissions
    ```


### ***Consumer Setup***

1. Clone the repository or download the Zip file.
    ```sh
    git clone https://github.com/kndonetm/stdiscm-p3-consumer.git
    ```

2. In a **(Ubuntu) WSL terminal**, navigate into the project.
    ```sh
    cd stdiscm-p3-consumer
    ```

3. Set up the configuration by copying the `.env.example template:`
    ```sh
    cp .env.example .env
    ```
    
    Edit the `.env` with required variables:
    ```ini
    NUM_CONSUMER_THREADS=4         # Adjust the number of consumer threads as needed
    MAX_QUEUE_LENGTH=10            # Set the maximum queue length for video uploads
    BOUND_ADDR=0.0.0.0             # Set the binding address for the consumer
    VIDEO_SERVER_PORT=3000         # Set the port for video server communication
    VIDEO_DIRECTORY=/path/to/videos   # Set the directory for received videos
    VIDEO_FRONTEND_PORT=3001       # Set the port for the frontend
    ```


4. Create storage directory for received videos.
    ```sh
    mkdir -p received_videos        # Creating file directory
    chmod 775 received_videos       # Setting up permissions
    ```

5. Install the dependencies.
    - **Frontend (Consumer):**
    ```sh
    cd consumer                     # Navigate inside the consumer
    bundle install                  # Install the dependencies
    ```

    - **Backend (Server)**
    ```sh
    cd ..                           # Go back to the project directory
    cd server                       # Navigate inside the server
    bundle install                  # Install the dependencies
    ```

## Execution
1. **Start the frontend (consumer):**

    Ensure you're in the consumer directory and run the following:
    ```sh
    cd consumer
    rails s -p 3001                 # Start the frontend on port 3001
    ```

2. **Start the backend (server) in a new terminal:**
    
    In a separate terminal, navigate to the server directory and run the server:
    ```sh
    cd server
    ruby test_consumer.rb           # Run the consumer backend
    ```

3. **Start the producer:**

    Finally, run the producer in a new terminal:
    ```sh
    ruby test_producer.rb           # Run the producer
    ```

4. View the frontend updates:

    Reload the page where the frontend is hosted (e.g., http://localhost:3001) to see the changes.