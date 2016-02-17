= How to install

1) Clone the project

2) make sure `bundle` is installed (e.g `gem bundle install`)

Make sure your installation works by running:

     brew install python
     brew linkapps python
     brew link python
     brew install qt5
     brew link --force qt5
     which qmake
     sudo easy_install pip
     sudo pip install mechanize
     gem install bundler
     bundle install


3) run `ruby ./statements.rb`
or
````
chmod +x statements.rb
./statements.rb
````

4) change your credentials in `credentials.yml` (rename the `credentials_EXAMPLE.yml` to `credentials.yml`).

5) File download should succeed with `./statements.rb`.

