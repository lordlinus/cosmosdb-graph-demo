FROM python:3.10-bullseye

# Install updates and dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y graphviz graphviz-dev
RUN apt-get clean autoclean && apt-get autoremove --yes && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Copy files to working directory
COPY . /src
WORKDIR /src

# Install python dependenciea
RUN pip install --upgrade pip && pip install -r requirements.txt

# Run streamlit app on default port
CMD streamlit run app.py