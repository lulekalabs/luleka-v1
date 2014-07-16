require 'model_security'
#ActiveRecord::Base.extend( ModelSecurity )
ActiveRecord::Base.send( :include, Probono::ModelSecurity )