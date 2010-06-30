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



module MobyController

	module QT

		module WidgetCommand 

			# Execute the command). 
			# Sends the message to the device using the @sut_adapter (see base class)     
			# == params         
			# == returns
			# == raises
			# NotImplementedError: raised if unsupported command type       
			def execute

			  builder = Nokogiri::XML::Builder.new{
				TasCommands( :id=> get_application_id, :transitions => get_transitions, :service => get_service || 'uiCommand' ) {
				  Target( :TasId => get_object_id, :type => get_object_type ) {
					if get_command_value.kind_of? Array
					  get_command_value.each do | command_part |
						Command( command_part[ :value ], command_part[ :params ] )
					  end
					else
					  Command( get_command_value || "", ( get_command_params || {} ).merge( :name => get_command_name ) )
					end
				  }
				}
			  }						  

			  if @sut_adapter.group?
				@sut_adapter.append_command(builder.doc.root.children)
			  else
				@sut_adapter.send_service_request(Comms::MessageGenerator.generate(builder.to_xml))
			  end

			end

			def set_adapter( adapter )
				@sut_adapter = adapter
			end

		end #module Action

	end #module QT

end #module MobyController

MobyUtil::Logger.instance.hook_methods( MobyController::QT::WidgetCommand )
