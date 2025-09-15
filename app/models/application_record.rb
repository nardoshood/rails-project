# The issue here is that the class is named `AppRecord` instead of the Rails convention `ApplicationRecord`.
# In Rails, the base model class should be named `ApplicationRecord` so that all models can inherit from it,
# and Rails features (like generators and some gems) expect this name.
# The correct code should be:

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end