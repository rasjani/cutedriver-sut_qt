############################################################################
## 
## Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies). 
## All rights reserved. 
## Contact: Nokia Corporation (testabilitydriver@nokia.com) 
## 
## This file is part of TDriver. 
## 
## If you have questions regarding the use of this file, please contact 
## Nokia at testabilitydriver@nokia.com . 
## 
## This library is free software; you can redistribute it and/or 
## modify it under the terms of the GNU Lesser General Public 
## License version 2.1 as published by the Free Software Foundation 
## and appearing in the file LICENSE.LGPL included in the packaging 
## of this file. 
## 
############################################################################

## DESCRIPTION
# This script will take .qm or .ts files from SUT
# to convert those into SQL tables to a server following 
# the TDriver table structure for locale data

## REQUIREMENTS
# mysql gem installed on the system
# QT's lconvert on the path

#require 'tdriver'
require 'nokogiri'
require 'tmpdir'
require 'base64'

module MobyBehaviour

  module QT

    module SUT

      include MobyBehaviour::QT::Behaviour

      # rebuilds localisation db
	  # database_file:: String overrides the :localisation_server_database_name tdriver configuration paramater if provided
      # ==raises
	  
	  	# == description
		# Creates a new localisation able for translation using the tdriver_parameters to locate the Localization DB. 
		# It uses the temporary folder to store temporary translation files.
		#
		# == arguments
		# path
		#  String
		#   description: Path where the translation files to upload to the database are found
		#   example: "/usr/me/tdriver/localization_files"
		#   default: "/"
		#
		# file
		#  String
		#   description: File names of the translation files to be uploaded.
		#	example:"*.ts"
		#	default: "*.qm"
		#
		# database_file
		#  String
		#   description: If this is provided it will overwrite the value set in the parameter ':localisation_server_database_name'
		#   example: "mysqlitedb.sqlite"
		#   default: nil
		#
		# column_names_map
		#  Hash
		#   description: Hash with the language codes from the translation files as keys and the desired column names as values
		#   example: {"en" => "en_GB"}
		#   default: {}
		#
		# == returns
		# nil
		#
		# == throws
		# 
      def create_locale_db(path = "/", file = "*.qm", database_file = nil, column_names_map = {} )

		db_type =  MobyUtil::Parameter[ :localisation_db_type ]
		host =  MobyUtil::Parameter[ :localisation_server_ip ]
		database_file = MobyUtil::Parameter[ :localisation_server_database_name ] if database_file.nil?
		username = MobyUtil::Parameter[ :localisation_server_username ]
		password = MobyUtil::Parameter[ :localisation_server_password ]
		
		db_connection = MobyUtil::DBConnection.new(  db_type, host, database_file, username, password )
		table_name = MobyUtil::Parameter[ :sut_qt ][ :localisation_server_database_tablename, "" ]
                
		begin
			tmp_path = MobyUtil::Parameter[:tmp_folder] + "/locale_db_tmp"
		rescue MobyUtil::ParameterNotFoundError
			tmp_path = Dir.tmpdir + "/locale_db_tmp"
		end
		
        if (File.directory? tmp_path)
          FileUtils.rm_rf(tmp_path)
        end
		
        if (File.directory? tmp_path)
        else
          FileUtils.mkdir(tmp_path)
        end

        list_of_files = receive_files( path, file, tmp_path )
		
        list_of_files.each do |e_file|
			begin
				MobyUtil::Localisation.upload_translation_file( e_file, table_name, db_connection, column_names_map)	
			rescue Exception => e
				puts "Error while uploading #{e_file}."
				puts e.message
			end
        end

        nil
      end

	  
	  private 
	  	  
      #receives files from SUT
      def receive_files(device_path, file, tmp_path)
        list_of_files = fixture("file", "list_files",
          {:file_name => file,
            :file_path => device_path}).split(';')
        new_list_of_files = Array.new
        list_of_files.each do |name|
          new_list_of_files.push( tmp_path + "/" + File.basename(name) )
          file = File.open(tmp_path + "/" + File.basename(name), 'w')
          file << Base64.decode64( fixture("file", "read_file", {:file_name => name}) )
          file.close
        end
        return new_list_of_files
      end

	# enable hooking for performance measurement & debug logging
	MobyUtil::Hooking.instance.hook_methods( self ) if defined?( MobyUtil::Hooking )

    end

  end

end
