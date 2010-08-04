Bananas - a simple ip addresses and spam manager for Rails 
==========================================================

Author: Roman Snitko
Contributions: Denis Lifanov

**Bananas** does three things:
  *  Watches requests from a particular ip address and files a report if requests happen too often
  (+ emails you, if you want that).
  *  Blocks access from ip addresses that have been filed in reports.
  *  Provides an interface to manage those reports.

Supports Rails 3.0.0rc. If you want Rails 2.3 version, check out the "rails2.3" branch.

If you hate reading docs, go see the screencast: http://vimeo.com/13620290 

Installation
============
1. Download the plugin

        git submodule add git://github.com/snitko/bananas.git vendor/plugins/bananas

2. Generate stuff

        script/generate bananas spam_report user

  The first argument "spam_report" is the name of the model you're going to use as a base for reports.
  The second argument - a name for the class that is supposed to be a potential abuser (usually "user") -
  is optional, although necessary if you're using ActiveRecord as a storage for attempts (see "Customizing" section).
  This command will do the following: generate `SpamReport` model and `SpamReportsController`,
  add resource route for `spam_reports` and create a migration.

3. Run `rake db:migrate`

4. Add the following lines to the `ApplicationController`:

        include Bananas
        bananas :spam_report

Usage
=====

Controller methods
------------------

To make this plugin actually do its job you would need two methods in your controller that have been
generated for you. Assuming that the model name you generated is `SpamReport` those methods's
names are `#cast_spam_report` and `#check_spam_report`.

`#cast_spam_report` is a method that tries to create a SpamReport.
I say "tries" because it only creates it if the conditions are right: if the time that
passed since its last call is less than a certain value and if there's been a certain number
of attempts to create a spam report (now would be the good time to take a look at your `SpamReport`
class and the default settings that's been generated there for you). This method takes one argument,
which is the id of the abuser (in our case it's `User`). The argument is optional, but again it's necessary
if you're using ActiveRecord as the "attempts" storage - **otherwise the plugin would file the report
unconditionally!** Here's an example of how it can be used:

    class PostsController
      def create
        if @post.create(:text => "New Post")
          cast_spam_report(current_user.id)
        end
      end
    end

`#check_spam_report` is a method that checks against existing SpamReports and blocks
access (by rendering 403 page) if the report for the current ip address exists. Here's a usage example:

    class PostsController
      before_filter :check_spam_report
    end

Both methods could be redefined, of course, if you wish something more customized. However,
I suggest you only customize the model as this is the place where all the logic is placed.
(see Customizing section)

Managing reports
----------------

To access the reports manager, just navigate your browser to `/spam_reports` and enter
login "login" and password "password". You may change them to something less guessable
in the `SpamReportsController` class. However, most of you would probably want to grant
access to the manager based on something else, possibly some existing application data.
That's simple. Just redefine `#authorize?` method. Here's an example:

    class SpamReportsController
      private
        def authorize?
          current_user.admin?
        end
    end

Customizing
===========

If you take a look at the options in those two generated classes you will find them
pretty self-descriptve. Here I'll concentrate on the more advanced issues.

Reports Create Conditions
--------------------------

When a report is created it must first satisfy a number of conditions.
Each condition is represented by a private method in `SpamReport` class.
There's only one such method pre-defined for you, it's called `#check_number_of_attempts`.

Others you can create yourself and add to the conditions list like that:

    class SpamReport

      create_condition [:check_user_location, :check_user_rating]

      private

        def check_user_location
          errors.add(:base, "No spammers in this town!") if abuser.location == "NYC"
        end

        def check_user_rating
          errors.add(:base, "This user can't be a spammer!") if abuser.rating > 100
        end

    end


Report Attempts storage
-----------------------

The `#check_number_of_attempts` method checks the number of report casting attempts
over the set period of time. If the number of attempts over this time is less then
a certain amount of "allowed" time, then it increments the number of attempts. If it's more,
then it creates a report and flashes attempts stack.

Now what you should know is that attempts are represented by timestamps.
Depending on the value of the `attempts_storage` option in `SpamReport` (:active_record or :cache) 
they're either stored in the `bananas_report` field of the `User` or in cache.

The latter is understandably faster, as you avoid 1 extra query to the database.
All you need to do is to provide an extra argument containing the cache storage:

    attempts_storage :cache, my_cache_storage

Alternatively, you can redefine `#check_number_of_attempts` method and store things
elsewhere.


Views
-----

If you don't like the standard views for the reports manager, just create
your own in `app/views/spam_reports`.


What's more?
------------
The interesting thing is that you may have as many report models as you wish
for different purposes. The only limitation is that a particular abuser model
can have relationship with only one particular report model.
