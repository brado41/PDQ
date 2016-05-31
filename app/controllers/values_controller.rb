class ValuesController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require 'rubygems'
  require 'open-uri'
  require 'json'
  require 'openssl'
  require 'date'
  require 'time'
  require 'mixpanel-ruby'

  ############################################################
  #  Coder Notes: always read before committing and pushing  #
  ############################################################
  #<^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^>#
  #<                                                        >#
  #<                                                        >#
  #<                                                        >#
  #<                                                        >#
  #<                                                        >#
  #<vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv>#
  ############################################################
  #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
  ############################################################

  # def getvalues
  #   # Call the original version of get values
  #   @addresses = GetValuesArchive.getValues(params)

  #   @allOutput = Output.all
  #   if params[:path] == nil
  #     return render 'getvalues'
  #   end

  #   @calcedurl = "/inspect/"+params[:street]+"/"+params[:citystatezip]
  #   return render 'blank'
  # end

  # under construction
  def getvalues
    # Track via mixpanel
    MiscFunctions.mixPanelTrack(params[:street], params[:citystatezip], params[:product])

    # Determine if this is a bulk run or single property
    if (params[:street].nil? || params[:citystatezip].nil?) && params[:placeid].nil?
      @addresses = Address.all
      runID = "Run: #{addresses.size}: #{Date.today.to_s}"

      # Loop over records and compute PDQ score
      @addresses.each { |prop| PdqEngine.computeDecision(prop, params, runID) }
      
    else # if single property, create new address record or use place id if passed
      runID = "#{params[:path].to_s.capitalize}: #{Date.today.to_s}"

      # If we are provided a placeid (not active)
      if !params[:placeid].nil?
        geo_data = GeoFunctions.getGoogleGeoByPlaceId(params[:placeid])
        search_add = PdqEngine.computeDecision(geo_data, params, runID)

      else
        # These functions take "unclean" address from Billboard URL and clean it
        street = MiscFunctions.addressStringClean(params[:street])
        citystatezip = MiscFunctions.addressStringClean(params[:citystatezip])

        # Create an "unclean" (archive) lookup address
        hist_lookup_add = Address.new
        hist_lookup_add.street = street
        hist_lookup_add.citystatezip = citystatezip

        # Get Google place id
        geo_data = GeoFunctions.getGoogleGeoByAddress(street, citystatezip)
        search_add = PdqEngine.computeDecision(geo_data, params, runID, alt_lookup = hist_lookup_add)
      end
      @addresses = [search_add]
    end

    # update parameters to match clean-address format
    # params[:street] = a.street
    # params[:citystatezip] = a.citystatezip

    # Aggregate all output and render
    @allOutput = Output.all
    return render 'getvalues' if params[:path].nil?

    # Search here

    # If request coming from billboard
    # @calcedurl = URI.escape("/inspect/#{params[:street]}/#{params[:citystatezip]}")
    @calcedurl = URI.escape("/inspect/#{search_add.street}/#{search_add.citystatezip}")
    puts @calcedurl
    return render 'blank'
  end

end