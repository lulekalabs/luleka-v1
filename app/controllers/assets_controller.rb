# Controller to manage assets, files, links
class AssetsController < FrontApplicationController
  
  #--- actions
  
  # This action returns an asset stream
  # Parameters:
  #   params[:id] => Asset ID
  #   params[:name] => 'preview'
  def show
    if @asset = Asset.find(params[:id])
      if @asset.accepts_user?(current_user)
        send_file( @asset.file( params[:name] ), {:disposition => 'inline', :type => @asset.content_type})
      end
    end
  end
  
  protected

  #--- actions from kase controller
  # TODO can be removed?
  
  # Ajax action for adding a file_select partial in create action
  def update_file_select
    case params[:checked]
    when /1/
      @index = 1
    when /undefined/, /0/
      @index = 0
      if @issue_id=params[:issue_id]
        if issue=Issue.find(@issue_id.to_i)
          issue.assets.destroy_all
        end
      end
    else
      @index = params[:index].to_i
    end
    instance_variable_set( "@asset#{@index}", Asset.new ) if @index>0
    render :action => 'update_file_select.rjs'
  end

  # Ajax action for removing the file_select partial in create action
  def remove_file_select
    if @index = params[:index].to_i
      instance_variable_set( "@asset#{@index}", nil )
      @index -= 1 if @index > 0
    end
    @issue_id = params[:issue_id]
    if @asset_id = params[:asset_id]
      if asset = Asset.find( @asset_id.to_i )
        asset.destroy
      end
    end
    render :action => 'update_file_select.rjs' if 0==@index
  end

  #--- actions from kase controller
  

end
