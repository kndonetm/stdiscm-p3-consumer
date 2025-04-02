# Networked Producer and Consumer
### ***Consumer Setup***


## Prerequisites
- Ruby 3.0+ 
    ```sh
    ruby -v                 # Check the version
    ```
- Bundler
    ```sh
    gem install bundler     # Installation
    ```
- Linux/WSL Terminal
- Network Access to consumer machine's port

## Setup Instructions
1. Clone the repository or download the Zip file.
    ```sh
    git clone https://github.com/kndonetm/stdiscm-p3-consumer.git
    ```
2. From a terminal, navigate into the project.
    ```sh
    cd stdiscm-p3-consumer
    ```
3. Install the dependencies.
    ```sh
    bundle install
    ```
4. Set up the configuration
    ```sh
    cp .env.example .env    # Copy the .env template
    ```
    - Edit the .env with required variables:
        - `NUM_CONSUMER_THREADS=`
        - `MAX_QUEUE_LENGTH=`
        - `PORT=`
        - `VIDEO_DIRECTORY=`
    ```ini
    PORT=3000               # Change as needed
    ```
5. Create storage directory for videos
    ```sh
    mkdir -p videos         # Creating file directory
    chmod 775 videos        # Setting up permissions
    ```

## Execution
```sh
ruby test_consumer.rb       # Run the consumer
```