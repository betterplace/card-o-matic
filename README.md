# Card-o-matic

Card-o-matic is a small web application which takes a Pivotal API key and generates printable cards for each story in the selected iteration. It's largely based on the design of [@psd's](http://whatfettle.com/) [pivotal-cards](https://github.com/psd/pivotal-cards) bookmarklet.

## Usage

```
bundle install
bundle exec unicorn -p 5000
```

Then visit <http://localhost:5000> in your browser.

### API Key

You need your Pivotal API key which you get at the bottom of https://www.pivotaltracker.com/profile

## Printing

This are my settings for google chrome:

![print-settings-for-pivotal-card-o-matic.png](images/print-settings-for-pivotal-card-o-matic.png "print-settings-for-pivotal-card-o-matic.png")
