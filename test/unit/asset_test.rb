require File.dirname(__FILE__) + '/../test_helper'

class AssetTest < ActiveSupport::TestCase
  ROOT = File.join(File.dirname(__FILE__), '..')
  fixtures :users, :people, :kases, :tiers, :topics

  def test_should_instantiate
    assert asset = Asset.new
    assert_equal :asset, asset.kind
  end

  def test_should_have_kind
    assert_equal :asset, Asset.kind
    assert_equal :asset, Asset.new.kind
  end

  def test_should_validate_asset
    assert asset = build_asset
    assert asset.valid?, 'should be valid'
  end

  def test_should_validate_file_asset
    assert asset = build_file_asset
    assert asset.valid?, 'should be valid'
  end
  
  def test_should_instantiate_file_asset
    asset = FileAsset.new
    assert asset.is_a?(FileAsset)
    assert asset.is_a?(Asset)
    assert_equal :file, asset.kind

    asset = Asset.new(:type => :file)
    assert asset.is_a?(FileAsset)
    assert asset.is_a?(Asset)
    assert_equal :file, asset.kind

    asset = Asset.new(:type => 'FileAsset')
    assert asset.is_a?(FileAsset)
    assert asset.is_a?(Asset)
    assert_equal :file, asset.kind

    asset = Asset.new(:type => FileAsset)
    assert asset.is_a?(FileAsset)
    assert asset.is_a?(Asset)
    assert_equal :file, asset.kind
  end
  
  def test_should_attach_file
    asset = build_file_asset
    asset.file = File.new(File.join(ROOT, "fixtures", "files", "beetle_48kb.jpg"), 'rb')
    assert asset.save, "should save"
    assert asset.file?,"should have file attached"
    assert asset.file(:thumb).match("thumb_beetle_48kb.jpg"), "should attach thumb"
    assert asset.file(:profile).match("profile_beetle_48kb.jpg"), "should attach profile"
    assert asset.file(:portrait).match("portrait_beetle_48kb.jpg"), "should attach portrait"
  end

  def test_should_not_validate_file
    asset = build_file_asset
    asset.file = File.new(File.join(ROOT, "fixtures", "files", "beetle_296kb.jpg"), 'rb')
    assert !asset.valid?, "should not validate file size"
    assert_equal "file size must be between 1 and 262144 bytes.", asset.errors.on(:file)
  end

  def test_should_not_validate_file_type
    asset = build_file_asset
    asset.file = File.new(File.join(ROOT, "fixtures", "files", "beetle_228kb.bmp"), 'rb')
    assert !asset.valid?, "should not validate file size"
    assert_equal "is not one of the allowed file types.", asset.errors.on(:file)
  end
  
  protected
  
  def valid_asset_attributes(options={})
    {
      :person => people(:homer),
      :assetable => kases(:powerplant_leak),
      :name => "Wow!"
    }.merge(options)
  end
  
  def build_asset(options={})
    Asset.new(valid_asset_attributes(options))
  end

  def create_asset(options={})
    Asset.create(valid_asset_attributes(options))
  end

  def valid_file_asset_attributes(options={})
    {
      :person => people(:homer),
      :assetable => kases(:powerplant_leak),
      :name => "Wow!"
    }.merge(options)
  end
  
  def build_file_asset(options={})
    FileAsset.new(valid_file_asset_attributes(options))
  end

  def create_file_asset(options={})
    FileAsset.create(valid_file_asset_attributes(options))
  end

end
