# Networked Producer and Consumer

## Prerequisites
Ensure the following are installed:
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

### ***Consumer Setup***

1. Clone the repository or download the Zip file.
    ```sh
    git clone https://github.com/kndonetm/stdiscm-p3-consumer.git
    ```

2. Navigate into the project.
    ```sh
    cd stdiscm-p3-consumer
    ```

3. Set up the configuration by copying the `.env.example template:`
    ```sh
    cp .env.example .env
    ```
    
    Edit the `.env` with required variables:
    ```ini
    # Configuration file for the video processing server
    NUM_CONSUMER_THREADS=4
    MAX_QUEUE_LENGTH=10
    BOUND_ADDR=0.0.0.0
    PORT=2000
    VIDEO_DIRECTORY="public/received_videos"
    
    # Blank = automatically assign ports for worker threads
    # Otherwise, comma-separated list of ports, e.g. "2001,2002,2003"
    # Must have length == NUM_CONSUMER_THREADS
    WORKER_THREAD_PORTS=
    ```

4. Install the dependencies.
    ```sh
    bundle install                  # Install the dependencies
    ```


### ***Producer Setup***
1. Clone the repository or download the Zip file.
    ```sh
    git clone https://github.com/kndonetm/stdiscm-p3-producer.git
    ```

2. Navigate into the project.
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
    # "localhost" or a valid IP address
    HOSTNAME=127.0.0.1
    
    # port for main thread
    PORT=2000
    
    # Comma-separated list of directories, e.g. "videos1,videos2,videos3"
    # 1 worker thread is generated per directory
    VIDEO_DIRECTORIES=cat_videos,dog_videos,other_animal_videos
    ```

## Execution
1. **Start the consumer:**

    Ensure you're in the consumer directory and run the following:
    ```sh
    rails s -p 3000                 # Start consumer
    ```

2. **Start the producer:**

    Ensure you're in the producer directory and run the following:
    ```sh
    ruby producer.rb           # Run the producer
    ```

4. View the frontend updates:

    Reload the page where the frontend is hosted (e.g., http://localhost:3000) to see the changes.
