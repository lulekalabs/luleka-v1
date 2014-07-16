class SetupSchema < ActiveRecord::Migration
  def self.up
    create_table "academic_titles", :force => true do |t|
      t.string "name"
      t.string "name_de"
      t.string "name_es"
    end

    add_index "academic_titles", ["name"], :name => "index_academic_titles_on_name"
    add_index "academic_titles", ["name_de"], :name => "index_academic_titles_on_name_de"

    create_table "addresses", :force => true do |t|
      t.integer  "addressable_id"
      t.string   "addressable_type"
      t.integer  "academic_title_id"
      t.string   "first_name"
      t.string   "middle_name"
      t.string   "gender",            :limit => 1
      t.string   "last_name"
      t.text     "street"
      t.string   "city"
      t.string   "postal_code"
      t.string   "province"
      t.string   "province_code",     :limit => 2
      t.string   "country"
      t.string   "country_code",      :limit => 2
      t.string   "company_name"
      t.text     "note"
      t.string   "phone"
      t.string   "mobile"
      t.string   "fax"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "type"
      t.float    "lat"
      t.float    "lng"
    end

    add_index "addresses", ["academic_title_id"], :name => "index_addresses_on_academic_title_id"
    add_index "addresses", ["addressable_id", "addressable_type"], :name => "fk_addresses_addressable"
    add_index "addresses", ["province"], :name => "index_addresses_on_state"
    add_index "addresses", ["province_code"], :name => "index_addresses_on_state_code"
    add_index "addresses", ["country"], :name => "index_addresses_on_country"
    add_index "addresses", ["country_code"], :name => "index_addresses_on_country_code"
    add_index "addresses", ["type"], :name => "index_addresses_on_type"
    add_index "addresses", ["city"], :name => "index_addresses_on_city"
    add_index "addresses", ["gender"], :name => "index_addresses_on_gender"
    add_index "addresses", ["first_name"], :name => "index_addresses_on_first_name"
    add_index "addresses", ["middle_name"], :name => "index_addresses_on_middle_name"
    add_index "addresses", ["last_name"], :name => "index_addresses_on_last_name"
    add_index "addresses", ["company_name"], :name => "index_addresses_on_company_name"
    add_index "addresses", ["phone"], :name => "index_addresses_on_phone"
    add_index "addresses", ["mobile"], :name => "index_addresses_on_mobile"
    add_index "addresses", ["fax"], :name => "index_addresses_on_fax"
    add_index "addresses", ["lng", "lat"], :name => "index_addresses_on_lng_and_lat"

    create_table "admin_users", :force => true do |t|
      t.string   "login"
      t.string   "email"
      t.string   "crypted_password",          :limit => 40
      t.string   "salt",                      :limit => 40
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "remember_token"
      t.datetime "remember_token_expires_at"
      t.string   "activation_code",           :limit => 40
      t.datetime "activated_at"
      t.string   "state",                                   :default => "passive"
      t.datetime "deleted_at"
    end

    add_index "admin_users", ["login"], :name => "index_admin_users_on_login"
    add_index "admin_users", ["email"], :name => "index_admin_users_on_email"

    create_table "assets", :force => true do |t|
      t.integer  "parent_id"
      t.integer  "person_id"
      t.integer  "assetable_id"
      t.string   "assetable_type"
      t.string   "url"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "file_file_name"
      t.string   "file_content_type"
      t.integer  "file_file_size"
      t.datetime "file_updated_at"
      t.string   "type"
      t.text     "description"
    end

    add_index "assets", ["parent_id"], :name => "index_assets_on_parent_id"
    add_index "assets", ["person_id"], :name => "index_assets_on_person_id"
    add_index "assets", ["assetable_id", "assetable_type"], :name => "fk_assets_assetable"

    create_table "audience_types", :force => true do |t|
      t.string   "kind",       :limit => 25, :null => false
      t.string   "name",       :limit => 65, :null => false
      t.string   "name_de",    :limit => 65, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name_es"
    end

    add_index "audience_types", ["kind"], :name => "index_audience_types_on_kind"

    create_table "bad_words", :force => true do |t|
      t.string "bad"
      t.string "good"
      t.string "bad_de"
      t.string "good_de"
      t.string "bad_es"
      t.string "good_es"
    end

    add_index "bad_words", ["bad"], :name => "index_bad_words_on_bad"
    add_index "bad_words", ["good"], :name => "index_bad_words_on_good"
    add_index "bad_words", ["bad_de"], :name => "index_bad_words_on_bad_de"
    add_index "bad_words", ["good_de"], :name => "index_bad_words_on_good_de"

    create_table "bids", :force => true do |t|
      t.integer  "bid_cents"
      t.integer  "current_bid_cents"
      t.string   "currency"
      t.integer  "bidder_id"
      t.integer  "biddable_id"
      t.string   "biddable_type"
      t.datetime "created_at"
    end

    add_index "bids", ["biddable_id", "biddable_type"], :name => "fk_bids_biddable"
    add_index "bids", ["bidder_id"], :name => "index_bids_on_bidder_id"

    create_table "cart_line_items", :force => true do |t|
      t.string   "item_number"
      t.string   "name"
      t.string   "description"
      t.integer  "quantity",                  :default => 1,       :null => false
      t.string   "unit",                      :default => "piece", :null => false
      t.integer  "pieces",                    :default => 0,       :null => false
      t.integer  "cents",                     :default => 0,       :null => false
      t.string   "currency",     :limit => 3, :default => "USD",   :null => false
      t.boolean  "taxable",                   :default => false,   :null => false
      t.integer  "product_id",                                     :null => false
      t.string   "product_type",                                   :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "cart_line_items", ["item_number"], :name => "index_cart_line_items_on_item_number"
    add_index "cart_line_items", ["name"], :name => "index_cart_line_items_on_name"
    add_index "cart_line_items", ["description"], :name => "index_cart_line_items_on_description"
    add_index "cart_line_items", ["quantity"], :name => "index_cart_line_items_on_quantity"
    add_index "cart_line_items", ["unit"], :name => "index_cart_line_items_on_unit"
    add_index "cart_line_items", ["pieces"], :name => "index_cart_line_items_on_pieces"
    add_index "cart_line_items", ["product_id", "product_type"], :name => "index_cart_line_items_on_product_id_and_product_type"

    create_table "comments", :force => true do |t|
      t.text     "message"
      t.datetime "created_at"
      t.integer  "parent_id"
      t.datetime "updated_at"
      t.datetime "deleted_at"
      t.integer  "corresponds_to_id"
      t.integer  "person_id"
      t.string   "type"
      t.integer  "commentable_id"
      t.string   "commentable_type"
      t.integer  "sender_id"
      t.integer  "receiver_id"
      t.string   "status",                         :default => "created", :null => false
      t.datetime "suspended_at"
      t.datetime "activated_at"
      t.string   "language_code",     :limit => 2
      t.string   "activation_code"
      t.datetime "published_at"
      t.string   "sender_email"
    end

    add_index "comments", ["person_id"], :name => "index_comments_on_person_id"
    add_index "comments", ["commentable_id", "commentable_type"], :name => "index_comments_on_commentable_id_and_commentable_type"
    add_index "comments", ["sender_id"], :name => "index_comments_on_sender_id"
    add_index "comments", ["receiver_id"], :name => "index_comments_on_receiver_id"
    add_index "comments", ["status"], :name => "index_comments_on_status"
    add_index "comments", ["language_code"], :name => "index_comments_on_language_code"
    add_index "comments", ["activation_code"], :name => "index_comments_on_activation_code"
    add_index "comments", ["published_at"], :name => "index_comments_on_published_at"
    add_index "comments", ["sender_email"], :name => "index_comments_on_sender_email"

    create_table "countings", :force => true do |t|
      t.integer  "outcome_id"
      t.integer  "poll_id"
      t.integer  "participant_id"
      t.datetime "created_at"
    end

    add_index "countings", ["outcome_id"], :name => "index_countings_on_outcome_id"
    add_index "countings", ["poll_id"], :name => "index_countings_on_poll_id"
    add_index "countings", ["participant_id"], :name => "index_countings_on_participant_id"

    create_table "delayed_jobs", :force => true do |t|
      t.integer  "priority",   :default => 0
      t.integer  "attempts",   :default => 0
      t.text     "handler"
      t.text     "last_error"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by"
      t.boolean  "schedule",   :default => false
      t.integer  "period"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "deliveries", :force => true do |t|
      t.string   "message_id"
      t.string   "recipient"
      t.text     "content"
      t.string   "status"
      t.datetime "created_at"
      t.datetime "modified_at"
    end

    create_table "deposit_accounts", :force => true do |t|
      t.integer  "person_id"
      t.string   "name"
      t.string   "logo"
      t.string   "paypal_account"
      t.string   "iban"
      t.string   "bic"
      t.string   "type"
      t.string   "status",         :limit => 25, :default => "created", :null => false
      t.datetime "activated_at"
    end

    add_index "deposit_accounts", ["person_id"], :name => "index_deposit_accounts_on_person_id"
    add_index "deposit_accounts", ["type"], :name => "index_deposit_accounts_on_type"
    add_index "deposit_accounts", ["status"], :name => "index_deposit_accounts_on_status"

    create_table "discussion_types", :force => true do |t|
      t.string   "kind",       :limit => 25, :null => false
      t.string   "name",       :limit => 65, :null => false
      t.string   "name_de",    :limit => 65
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name_es",    :limit => 65
    end

    add_index "discussion_types", ["kind"], :name => "index_discussion_types_on_kind"

    create_table "exchange_rates", :force => true do |t|
      t.string   "from_currency", :limit => 3
      t.string   "to_currency",   :limit => 3
      t.float    "rate"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "exchange_rates", ["from_currency"], :name => "index_exchange_rates_on_from_currency"
    add_index "exchange_rates", ["to_currency"], :name => "index_exchange_rates_on_to_currency"

    create_table "flags", :force => true do |t|
      t.integer  "user_id"
      t.integer  "flaggable_id"
      t.string   "flaggable_type"
      t.integer  "flaggable_user_id"
      t.string   "reason"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "flags", ["user_id"], :name => "index_flags_on_user_id"
    add_index "flags", ["flaggable_user_id"], :name => "index_flags_on_flaggable_user_id"
    add_index "flags", ["flaggable_id", "flaggable_type"], :name => "index_flags_on_flaggable_id_and_flaggable_type"
    add_index "flags", ["reason"], :name => "index_flags_on_reason"

    create_table "follows", :force => true do |t|
      t.integer  "followable_id",                      :null => false
      t.string   "followable_type"
      t.integer  "follower_id",                        :null => false
      t.string   "follower_type"
      t.boolean  "blocked",         :default => false, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "follows", ["follower_id", "follower_type"], :name => "fk_follows"
    add_index "follows", ["followable_id", "followable_type"], :name => "fk_followables"

    create_table "friendships", :force => true do |t|
      t.integer  "person_id",   :null => false
      t.integer  "friend_id",   :null => false
      t.datetime "created_at"
      t.datetime "accepted_at"
    end

    add_index "friendships", ["person_id"], :name => "index_friendships_on_person_id"
    add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"

    create_table "gateways", :force => true do |t|
      t.string "name",            :null => false
      t.string "mode"
      t.string "type"
      t.string "login_id"
      t.string "transaction_key"
    end

    add_index "gateways", ["name"], :name => "index_gateways_on_name"
    add_index "gateways", ["type"], :name => "index_gateways_on_type"

    create_table "globalize_countries", :force => true do |t|
      t.string "code",                   :limit => 2
      t.string "english_name"
      t.string "currency_code",          :limit => 3
      t.string "thousands_sep",          :limit => 2
      t.string "decimal_sep",            :limit => 2
      t.string "currency_decimal_sep",   :limit => 2
      t.string "number_grouping_scheme"
      t.string "short_time_format"
      t.string "standard_letter_format"
      t.string "tax_label"
      t.string "short_date_format"
      t.string "date_format"
      t.string "tax_mask"
      t.string "city_format"
      t.string "currency_format"
      t.string "tax_regexp"
      t.string "time_format"
      t.string "name"
      t.string "name_de"
    end

    add_index "globalize_countries", ["code"], :name => "index_globalize_countries_on_code"
    add_index "globalize_countries", ["name"], :name => "index_globalize_countries_on_name"
    add_index "globalize_countries", ["name_de"], :name => "index_globalize_countries_on_name_de"

    create_table "globalize_languages", :force => true do |t|
      t.string  "iso_639_1",             :limit => 2
      t.string  "iso_639_2",             :limit => 3
      t.string  "iso_639_3",             :limit => 3
      t.string  "rfc_3066"
      t.string  "english_name"
      t.string  "english_name_locale"
      t.string  "english_name_modifier"
      t.string  "native_name"
      t.string  "native_name_locale"
      t.string  "native_name_modifier"
      t.boolean "macro_language"
      t.string  "direction"
      t.string  "pluralization"
      t.string  "scope",                 :limit => 1
    end

    add_index "globalize_languages", ["iso_639_1"], :name => "index_globalize_languages_on_iso_639_1"
    add_index "globalize_languages", ["iso_639_2"], :name => "index_globalize_languages_on_iso_639_2"
    add_index "globalize_languages", ["iso_639_3"], :name => "index_globalize_languages_on_iso_639_3"
    add_index "globalize_languages", ["rfc_3066"], :name => "index_globalize_languages_on_rfc_3066"

    create_table "globalize_regions", :force => true do |t|
      t.string "code",         :limit => 2
      t.string "iso_3166_1",   :limit => 2
      t.string "iso_3166_2",   :limit => 5
      t.string "english_name"
      t.string "native_name"
    end

    add_index "globalize_regions", ["code"], :name => "index_globalize_regions_on_code"
    add_index "globalize_regions", ["iso_3166_1"], :name => "index_globalize_regions_on_iso_3166_1"
    add_index "globalize_regions", ["iso_3166_2"], :name => "index_globalize_regions_on_iso_3166_2"

    create_table "globalize_translations", :force => true do |t|
      t.string  "type"
      t.string  "tr_key"
      t.string  "table_name"
      t.integer "item_id"
      t.string  "facet"
      t.integer "language_id"
      t.integer "pluralization_index"
      t.text    "text"
      t.string  "namespace"
      t.boolean "built_in",            :default => false
    end

    add_index "globalize_translations", ["tr_key", "language_id"], :name => "index_globalize_translations_on_tr_key_and_language_id"
    add_index "globalize_translations", ["table_name", "item_id", "language_id"], :name => "globalize_translations_table_name_and_item_and_language"

    create_table "invoices", :force => true do |t|
      t.integer  "buyer_id"
      t.string   "buyer_type"
      t.integer  "seller_id"
      t.string   "seller_type"
      t.integer  "net_cents",    :default => 0,         :null => false
      t.integer  "tax_cents",    :default => 0,         :null => false
      t.integer  "gross_cents",  :default => 0,         :null => false
      t.float    "tax_rate",     :default => 0.0,       :null => false
      t.string   "currency",     :default => "USD",     :null => false
      t.string   "type"
      t.string   "number"
      t.boolean  "lock_version", :default => false,     :null => false
      t.string   "status",       :default => "pending", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "paid_at"
    end

    add_index "invoices", ["buyer_id", "buyer_type"], :name => "index_invoices_on_buyer_id_and_buyer_type"
    add_index "invoices", ["seller_id", "seller_type"], :name => "index_invoices_on_seller_id_and_seller_type"
    add_index "invoices", ["type"], :name => "index_invoices_on_type"
    add_index "invoices", ["number"], :name => "index_invoices_on_number"

    create_table "kases", :force => true do |t|
      t.integer  "category_id"
      t.integer  "person_id"
      t.string   "title"
      t.text     "description"
      t.string   "language_code",                 :limit => 2
      t.integer  "price_cents",                                :default => 0,         :null => false
      t.integer  "fixed_price_cents",                          :default => 0,         :null => false
      t.integer  "max_price_cents",                            :default => 0,         :null => false
      t.integer  "current_bid_cents",                          :default => 0
      t.string   "currency"
      t.float    "lat"
      t.float    "lng"
      t.string   "status",                                     :default => "created", :null => false
      t.integer  "visits_count",                               :default => 0
      t.datetime "created_at"
      t.datetime "started_at"
      t.datetime "updated_at"
      t.datetime "expires_at"
      t.integer  "assigned_person_id"
      t.integer  "time_to_solve"
      t.datetime "opened_at"
      t.datetime "auctioned_at"
      t.datetime "assigned_at"
      t.datetime "resolved_at"
      t.datetime "closed_at"
      t.integer  "comments_count",                             :default => 0
      t.string   "type"
      t.string   "permalink"
      t.integer  "severity_id"
      t.datetime "suspended_at"
      t.datetime "deleted_at"
      t.integer  "offer_type_id",                                                     :null => false
      t.integer  "offer_audience_type_id",                                            :null => false
      t.integer  "discussion_type_id",                                                :null => false
      t.boolean  "featured",                                   :default => false,     :null => false
      t.datetime "happened_at"
      t.integer  "clarification_requests_count",               :default => 0
      t.integer  "clarification_responses_count",              :default => 0
      t.integer  "votes_count",                                :default => 0
      t.integer  "up_votes_count"
      t.integer  "down_votes_count"
      t.integer  "votes_sum",                                  :default => 0
      t.integer  "views_count",                                :default => 0
      t.integer  "version"
      t.integer  "responses_count",                            :default => 0
      t.integer  "followers_count",                            :default => 0
      t.string   "activation_code"
      t.datetime "published_at"
      t.string   "sender_email"
      t.boolean  "template",                                   :default => false
    end

    add_index "kases", ["category_id"], :name => "fk_issues_category"
    add_index "kases", ["person_id"], :name => "fk_issues_person"
    add_index "kases", ["type"], :name => "index_kases_on_type"
    add_index "kases", ["permalink"], :name => "index_kases_on_permalink"
    add_index "kases", ["language_code"], :name => "index_kases_on_language_code"
    add_index "kases", ["severity_id"], :name => "index_kases_on_severity_id"
    add_index "kases", ["lng", "lat"], :name => "index_kases_on_lng_and_lat"
    add_index "kases", ["offer_type_id"], :name => "index_kases_on_offer_type_id"
    add_index "kases", ["offer_audience_type_id"], :name => "index_kases_on_offer_audience_type_id"
    add_index "kases", ["discussion_type_id"], :name => "index_kases_on_discussion_type_id"
    add_index "kases", ["featured"], :name => "index_kases_on_featured"
    add_index "kases", ["activation_code"], :name => "index_kases_on_activation_code"
    add_index "kases", ["published_at"], :name => "index_kases_on_published_at"
    add_index "kases", ["sender_email"], :name => "index_kases_on_sender_email"

    create_table "kontexts", :force => true do |t|
      t.integer  "kase_id"
      t.integer  "tier_id"
      t.integer  "topic_id"
      t.datetime "updated_at"
      t.datetime "created_at"
      t.integer  "location_id"
    end

    add_index "kontexts", ["kase_id"], :name => "index_kontexts_on_kase_id"
    add_index "kontexts", ["tier_id"], :name => "index_kontexts_on_organization_id"
    add_index "kontexts", ["topic_id"], :name => "index_kontexts_on_product_id"
    add_index "kontexts", ["location_id"], :name => "index_kontexts_on_location_id"

    create_table "line_items", :force => true do |t|
      t.integer "order_id"
      t.integer "invoice_id"
      t.integer "sellable_id"
      t.string  "sellable_type"
      t.integer "net_cents"
      t.string  "currency"
      t.integer "tax_cents",     :default => 0,   :null => false
      t.integer "gross_cents",   :default => 0,   :null => false
      t.float   "tax_rate",      :default => 0.0, :null => false
    end

    add_index "line_items", ["order_id"], :name => "index_line_items_on_order_id"
    add_index "line_items", ["invoice_id"], :name => "index_line_items_on_invoice_id"
    add_index "line_items", ["sellable_id", "sellable_type"], :name => "fk_line_items_sellable"

    create_table "memberships", :force => true do |t|
      t.integer  "person_id"
      t.integer  "tier_id"
      t.string   "status",                     :default => "passive", :null => false
      t.datetime "created_at"
      t.datetime "activated_at"
      t.datetime "updated_at"
      t.string   "type"
      t.string   "role",         :limit => 45
    end

    add_index "memberships", ["person_id"], :name => "fk_employments_person"
    add_index "memberships", ["tier_id"], :name => "fk_employments_company"

    create_table "messages", :force => true do |t|
      t.string   "type"
      t.integer  "sender_id"
      t.integer  "receiver_id"
      t.integer  "voucher_id"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "email"
      t.string   "language"
      t.text     "message"
      t.string   "uuid"
      t.string   "status",                        :default => "queued", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "sent_at"
      t.datetime "reminded_at"
      t.integer  "parent_id"
      t.integer  "tier_id"
      t.integer  "topic_id"
      t.integer  "group_id"
      t.string   "phone",           :limit => 45
      t.string   "role",            :limit => 45
      t.string   "activation_code", :limit => 40
      t.datetime "accepted_at"
      t.datetime "declined_at"
      t.datetime "deleted_at"
    end

    add_index "messages", ["type"], :name => "index_messages_on_type"
    add_index "messages", ["sender_id"], :name => "index_messages_on_sender_id"
    add_index "messages", ["receiver_id"], :name => "index_messages_on_receiver_id"
    add_index "messages", ["first_name"], :name => "index_messages_on_first_name"
    add_index "messages", ["last_name"], :name => "index_messages_on_last_name"
    add_index "messages", ["email"], :name => "index_messages_on_email"
    add_index "messages", ["uuid"], :name => "index_messages_on_uuid"
    add_index "messages", ["status"], :name => "index_messages_on_status"
    add_index "messages", ["sent_at"], :name => "index_messages_on_sent_at"
    add_index "messages", ["reminded_at"], :name => "index_messages_on_reminded_at"
    add_index "messages", ["parent_id"], :name => "index_messages_on_parent_id"
    add_index "messages", ["tier_id"], :name => "index_messages_on_tier_id"
    add_index "messages", ["topic_id"], :name => "index_messages_on_topic_id"
    add_index "messages", ["group_id"], :name => "index_messages_on_group_id"
    add_index "messages", ["activation_code"], :name => "index_messages_on_activation_code"

    create_table "offer_types", :force => true do |t|
      t.string   "kind",       :limit => 25, :null => false
      t.string   "name",       :limit => 65, :null => false
      t.string   "name_de",    :limit => 65, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name_es"
    end

    add_index "offer_types", ["kind"], :name => "index_offer_types_on_kind"

    create_table "orders", :force => true do |t|
      t.integer  "buyer_id"
      t.string   "buyer_type"
      t.integer  "seller_id"
      t.string   "seller_type"
      t.integer  "invoice_id"
      t.integer  "net_cents",                 :default => 0,         :null => false
      t.integer  "tax_cents",                 :default => 0,         :null => false
      t.integer  "gross_cents",               :default => 0,         :null => false
      t.string   "currency",     :limit => 3, :default => "USD",     :null => false
      t.float    "tax_rate",                  :default => 0.0,       :null => false
      t.string   "type"
      t.boolean  "lock_version",              :default => false,     :null => false
      t.string   "status",                    :default => "created", :null => false
      t.string   "number"
      t.string   "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "canceled_at"
    end

    add_index "orders", ["buyer_id", "buyer_type"], :name => "index_orders_on_buyer_id_and_buyer_type"
    add_index "orders", ["seller_id", "seller_type"], :name => "index_orders_on_seller_id_and_seller_type"
    add_index "orders", ["type"], :name => "index_orders_on_type"
    add_index "orders", ["status"], :name => "index_orders_on_status"

    create_table "outcomes", :force => true do |t|
      t.integer  "poll_id"
      t.string   "label"
      t.integer  "count",      :default => 0
      t.datetime "created_at"
    end

    add_index "outcomes", ["poll_id"], :name => "index_outcomes_on_poll_id"

    create_table "pages", :force => true do |t|
      t.string   "title"
      t.string   "permalink"
      t.text     "content"
      t.string   "layout"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "title_de"
      t.text     "content_de"
      t.string   "permalink_de"
      t.boolean  "markdown",                   :default => false, :null => false
      t.boolean  "textile",                    :default => false, :null => false
      t.string   "title_es"
      t.text     "content_es"
      t.string   "permalink_es"
      t.string   "dom_id",       :limit => 64
      t.string   "dom_class",    :limit => 64
    end

    add_index "pages", ["permalink"], :name => "index_pages_on_uri"
    add_index "pages", ["permalink_de"], :name => "index_pages_on_permalink_de"
    add_index "pages", ["permalink_es"], :name => "index_pages_on_permalink_es"

    create_table "payments", :force => true do |t|
      t.integer  "payable_id"
      t.string   "payable_type"
      t.boolean  "success"
      t.string   "reference"
      t.string   "message"
      t.string   "action"
      t.string   "params"
      t.boolean  "test"
      t.integer  "cents",                     :default => 0,     :null => false
      t.string   "currency",     :limit => 3, :default => "USD", :null => false
      t.integer  "lock_version",              :default => 0,     :null => false
      t.integer  "position"
      t.string   "type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "payments", ["payable_id", "payable_type"], :name => "index_payments_on_payable_id_and_payable_type"
    add_index "payments", ["reference"], :name => "index_payments_on_reference"
    add_index "payments", ["message"], :name => "index_payments_on_message"
    add_index "payments", ["action"], :name => "index_payments_on_action"
    add_index "payments", ["params"], :name => "index_payments_on_params"
    add_index "payments", ["position"], :name => "index_payments_on_position"

    create_table "people", :force => true do |t|
      t.integer  "academic_title_id"
      t.string   "first_name"
      t.string   "middle_name"
      t.string   "last_name"
      t.string   "email"
      t.string   "home_page_url"
      t.string   "blog_url"
      t.integer  "personal_status_id"
      t.text     "summary"
      t.string   "tax_code"
      t.integer  "default_response_quota"
      t.integer  "current_response_quota"
      t.datetime "response_quota_updated_at"
      t.float    "lat"
      t.float    "lng"
      t.boolean  "prefers_casual",                                 :default => false,     :null => false
      t.string   "status",                                         :default => "created", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "visits_count",                                   :default => 0
      t.boolean  "notify_on_newsletter",                           :default => true,      :null => false
      t.boolean  "notify_on_promotion",                            :default => false,     :null => false
      t.boolean  "notify_on_clarification_request",                :default => true,      :null => false
      t.boolean  "notify_on_clarification_response",               :default => true,      :null => false
      t.boolean  "notify_on_kase_matching",                        :default => true,      :null => false
      t.boolean  "notify_on_kase_status",                          :default => true,      :null => false
      t.boolean  "notify_on_comment_posted",                       :default => true,      :null => false
      t.boolean  "notify_on_comment_received",                     :default => true,      :null => false
      t.boolean  "notify_on_follower",                             :default => false,     :null => false
      t.boolean  "notify_on_following",                            :default => false,     :null => false
      t.integer  "voucher_quota"
      t.string   "gender",                           :limit => 1
      t.string   "permalink"
      t.datetime "permalink_at"
      t.string   "avatar_file_name"
      t.string   "avatar_content_type"
      t.integer  "avatar_file_size"
      t.datetime "avatar_updated_at"
      t.datetime "partner_at"
      t.string   "twitter_name",                     :limit => 20
      t.boolean  "notify_on_response_posted",                      :default => false,     :null => false
      t.boolean  "notify_on_response_received",                    :default => true,      :null => false
      t.boolean  "featured",                                       :default => false,     :null => false
      t.text     "summary_de"
      t.text     "summary_es"
      t.integer  "views_count",                                    :default => 0
      t.integer  "followers_count",                                :default => 0
      t.integer  "friends_count",                                  :default => 0
      t.integer  "kases_count",                                    :default => 1
      t.integer  "responses_count",                                :default => 0
      t.integer  "received_votes_count",                           :default => 0
      t.integer  "received_up_votes_count",                        :default => 0
      t.integer  "received_down_votes_count",                      :default => 0
      t.string   "uuid"
    end

    add_index "people", ["academic_title_id"], :name => "index_people_on_academic_title_id"
    add_index "people", ["personal_status_id"], :name => "index_people_on_personal_status_id"
    add_index "people", ["gender"], :name => "index_people_on_gender"
    add_index "people", ["permalink"], :name => "index_people_on_permalink"
    add_index "people", ["permalink_at"], :name => "index_people_on_permalink_at"
    add_index "people", ["lng", "lat"], :name => "index_people_on_lng_and_lat"
    add_index "people", ["featured"], :name => "index_people_on_featured"

    create_table "people_spoken_languages", :id => false, :force => true do |t|
      t.integer "person_id"
      t.integer "spoken_language_id"
    end

    add_index "people_spoken_languages", ["person_id", "spoken_language_id"], :name => "fk_person_language"

    create_table "personal_statuses", :force => true do |t|
      t.string "name"
      t.string "name_de"
      t.string "name_es"
    end

    create_table "piggy_bank_account_transactions", :force => true do |t|
      t.integer  "piggy_bank_account_id"
      t.string   "action"
      t.datetime "created_at"
      t.integer  "cents",                 :default => 0, :null => false
      t.string   "currency"
      t.string   "context_type"
      t.integer  "context_id"
      t.datetime "expires_at"
      t.string   "description"
      t.string   "authorization"
      t.datetime "voided_at"
      t.datetime "captured_at"
      t.string   "number"
    end

    add_index "piggy_bank_account_transactions", ["piggy_bank_account_id"], :name => "index_account_transactions_on_bank_account_id"
    add_index "piggy_bank_account_transactions", ["action"], :name => "index_account_transactions_on_action"
    add_index "piggy_bank_account_transactions", ["context_type"], :name => "index_account_transactions_on_sellable_type"
    add_index "piggy_bank_account_transactions", ["context_id"], :name => "index_account_transactions_on_sellable_id"
    add_index "piggy_bank_account_transactions", ["number"], :name => "index_piggy_bank_account_transactions_on_number"

    create_table "piggy_bank_accounts", :force => true do |t|
      t.integer  "cents",                :default => 0,     :null => false
      t.string   "currency",             :default => "USD"
      t.integer  "authorizations_count", :default => 0
      t.integer  "owner_id"
      t.string   "owner_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "piggy_bank_accounts", ["owner_id", "owner_type"], :name => "index_piggy_bank_accounts_on_owner_id_and_owner_type"
    add_index "piggy_bank_accounts", ["cents"], :name => "index_piggy_bank_accounts_on_cents"

    create_table "polls", :force => true do |t|
      t.string   "title"
      t.integer  "total",         :default => 0
      t.integer  "pollable_id",                  :null => false
      t.string   "pollable_type",                :null => false
      t.integer  "active",        :default => 0
      t.datetime "created_at",                   :null => false
      t.datetime "expires_at",                   :null => false
    end

    add_index "polls", ["pollable_id", "pollable_type"], :name => "index_polls_on_pollable_id_and_pollable_type"

    create_table "product_lines", :force => true do |t|
      t.integer  "person_id"
      t.integer  "purchasable_id"
      t.string   "purchasable_type"
      t.integer  "product_line_id"
      t.string   "sku"
      t.string   "title"
      t.text     "description"
      t.integer  "quantity"
      t.string   "unit"
      t.integer  "pieces"
      t.integer  "cents"
      t.string   "currency"
      t.float    "percentage"
      t.integer  "base_fee_cents"
      t.datetime "created_at"
      t.boolean  "taxable",          :default => true, :null => false
    end

    add_index "product_lines", ["person_id"], :name => "fk_product_lines_person"
    add_index "product_lines", ["purchasable_id", "purchasable_type"], :name => "fk_product_line_purchasable"
    add_index "product_lines", ["product_line_id"], :name => "fk_product_lines_product_line"
    add_index "product_lines", ["sku"], :name => "index_product_lines_on_sku"

    create_table "product_prices", :force => true do |t|
      t.integer "cents"
      t.string  "currency"
      t.float   "percentage"
    end

    create_table "products_product_prices", :force => true do |t|
      t.integer "product_id"
      t.integer "product_price_id"
    end

    add_index "products_product_prices", ["product_id"], :name => "index_products_product_prices_on_product_id"
    add_index "products_product_prices", ["product_price_id"], :name => "index_products_product_prices_on_product_price_id"

    create_table "ratings", :force => true do |t|
      t.integer  "rating"
      t.integer  "rater_id"
      t.integer  "rateable_id",   :null => false
      t.string   "rateable_type", :null => false
      t.datetime "created_at"
      t.string   "body"
      t.datetime "updated_at"
    end

    add_index "ratings", ["rateable_id", "rating"], :name => "index_ratings_on_rateable_id_and_rating"
    add_index "ratings", ["rater_id"], :name => "index_ratings_on_rater_id"

    create_table "responses", :force => true do |t|
      t.integer  "kase_id"
      t.integer  "person_id"
      t.text     "description"
      t.datetime "created_at"
      t.string   "status",                                     :default => "created", :null => false
      t.datetime "updated_at"
      t.datetime "activated_at"
      t.datetime "suspended_at"
      t.datetime "deleted_at"
      t.datetime "accepted_at"
      t.integer  "severity_id"
      t.string   "language_code",                 :limit => 2
      t.integer  "clarification_requests_count",               :default => 0
      t.integer  "clarification_responses_count",              :default => 0
      t.integer  "votes_count",                                :default => 0
      t.integer  "up_votes_count"
      t.integer  "down_votes_count"
      t.integer  "votes_sum",                                  :default => 0
      t.integer  "ratings_count",                              :default => 0
      t.integer  "ratings_average",                            :default => 0
      t.string   "activation_code"
      t.datetime "published_at"
      t.string   "sender_email"
      t.integer  "comments_count",                             :default => 0
    end

    add_index "responses", ["kase_id"], :name => "fk_responses_issue"
    add_index "responses", ["person_id"], :name => "fk_responses_person"
    add_index "responses", ["severity_id"], :name => "index_responses_on_severity_id"
    add_index "responses", ["language_code"], :name => "index_responses_on_language_code"
    add_index "responses", ["activation_code"], :name => "index_responses_on_activation_code"
    add_index "responses", ["published_at"], :name => "index_responses_on_published_at"
    add_index "responses", ["sender_email"], :name => "index_responses_on_sender_email"

    create_table "rights", :force => true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "rights", ["name"], :name => "index_rights_on_name"

    create_table "rights_roles", :id => false, :force => true do |t|
      t.integer "right_id"
      t.integer "role_id"
    end

    add_index "rights_roles", ["right_id"], :name => "index_rights_roles_on_right_id"
    add_index "rights_roles", ["role_id"], :name => "index_rights_roles_on_role_id"

    create_table "roles", :force => true do |t|
      t.string   "name"
      t.string   "authorizable_type"
      t.integer  "authorizable_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "roles", ["name"], :name => "index_roles_on_name"
    add_index "roles", ["authorizable_id", "authorizable_type"], :name => "fk_roles_authorizable"

    create_table "roles_users", :id => false, :force => true do |t|
      t.integer  "user_id"
      t.integer  "role_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"
    add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"

    create_table "sessions", :force => true do |t|
      t.string   "session_id"
      t.text     "data"
      t.datetime "updated_at"
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

    create_table "severities", :force => true do |t|
      t.integer "weight",                   :default => 0, :null => false
      t.string  "kind",       :limit => 25
      t.string  "name",       :limit => 35
      t.string  "name_de",    :limit => 35
      t.string  "feeling"
      t.string  "feeling_de"
      t.string  "name_es"
      t.string  "feeling_es"
    end

    add_index "severities", ["weight"], :name => "index_severities_on_weight"
    add_index "severities", ["kind"], :name => "index_severities_on_kind"
    add_index "severities", ["name"], :name => "index_severities_on_name"
    add_index "severities", ["name_de"], :name => "index_severities_on_name_de"

    create_table "spoken_languages", :force => true do |t|
      t.string "name"
      t.string "code",        :limit => 3
      t.string "native_name"
      t.string "name_de"
      t.string "name_es"
    end

    add_index "spoken_languages", ["name"], :name => "index_spoken_languages_on_name"
    add_index "spoken_languages", ["native_name"], :name => "index_spoken_languages_on_native_name"
    add_index "spoken_languages", ["name_de"], :name => "index_spoken_languages_on_name_de"
    add_index "spoken_languages", ["code"], :name => "index_spoken_languages_on_code"

    create_table "subscriptions", :force => true do |t|
      t.integer  "person_id"
      t.integer  "length_in_issues", :default => 0,         :null => false
      t.date     "last_renewal_on"
      t.boolean  "auto_renew",       :default => false,     :null => false
      t.integer  "product_id"
      t.string   "status",           :default => "created", :null => false
      t.datetime "created_at"
      t.datetime "activated_at"
      t.datetime "suspended_at"
    end

    add_index "subscriptions", ["person_id"], :name => "index_subscriptions_on_person_id"
    add_index "subscriptions", ["product_id"], :name => "index_subscriptions_on_product_id"

    create_table "taggings", :force => true do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.string   "taggable_type"
      t.string   "context"
      t.string   "name"
      t.datetime "created_at"
    end

    add_index "taggings", ["name"], :name => "index_taggings_on_name"
    add_index "taggings", ["context"], :name => "index_taggings_on_context"

    create_table "tags", :force => true do |t|
      t.string  "name"
      t.integer "taggings_count", :default => 0
    end

    add_index "tags", ["name"], :name => "index_tags_on_name"

    create_table "tax_rates", :force => true do |t|
      t.string "kind"
      t.float  "rate"
      t.string "country_code",  :limit => 5
      t.string "province_code"
    end

    add_index "tax_rates", ["country_code"], :name => "index_tax_rates_on_country_code"
    add_index "tax_rates", ["province_code"], :name => "index_tax_rates_on_state_code"

    create_table "tier_categories", :force => true do |t|
      t.string   "name"
      t.string   "name_de"
      t.string   "name_es"
      t.string   "kind"
      t.string   "super_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "tier_categories", ["kind"], :name => "index_tier_categories_on_kind"
    add_index "tier_categories", ["super_type"], :name => "index_tier_categories_on_super_type"
    add_index "tier_categories", ["name"], :name => "index_tier_categories_on_name"
    add_index "tier_categories", ["name_de"], :name => "index_tier_categories_on_name_de"
    add_index "tier_categories", ["name_es"], :name => "index_tier_categories_on_name_es"

    create_table "tiers", :force => true do |t|
      t.integer  "parent_id"
      t.string   "name"
      t.string   "tagline"
      t.string   "site_url"
      t.string   "tax_code"
      t.float    "lat"
      t.float    "lng"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "type"
      t.string   "site_name"
      t.string   "status",                           :default => "passive", :null => false
      t.string   "country_code",       :limit => 2
      t.string   "name_de"
      t.text     "description"
      t.text     "description_de"
      t.datetime "activated_at"
      t.string   "permalink"
      t.integer  "created_by_id"
      t.string   "activation_code",    :limit => 40
      t.datetime "deleted_at"
      t.string   "image_file_name"
      t.string   "image_content_type"
      t.integer  "image_file_size"
      t.datetime "image_updated_at"
      t.string   "name_es"
      t.text     "description_es"
      t.boolean  "featured",                         :default => false,     :null => false
      t.text     "summary"
      t.text     "summary_de"
      t.text     "summary_es"
      t.integer  "kases_count",                      :default => 0
      t.integer  "members_count",                    :default => 0
      t.integer  "topics_count",                     :default => 0
      t.string   "twitter_name"
      t.integer  "tier_category_id"
      t.string   "logo_file_name"
      t.string   "logo_content_type"
      t.integer  "logo_file_size"
      t.datetime "logo_updated_at"
      t.string   "language_code",      :limit => 2
      t.integer  "people_count",                     :default => 0
      t.string   "uuid"
    end

    add_index "tiers", ["parent_id"], :name => "index_companies_on_parent_id"
    add_index "tiers", ["type"], :name => "index_organizations_on_type"
    add_index "tiers", ["site_name"], :name => "index_organizations_on_site_name"
    add_index "tiers", ["status"], :name => "index_organizations_on_status"
    add_index "tiers", ["country_code"], :name => "index_organizations_on_country_code"
    add_index "tiers", ["name_de"], :name => "index_organizations_on_name_de"
    add_index "tiers", ["created_by_id"], :name => "index_organizations_on_created_by_id"
    add_index "tiers", ["activation_code"], :name => "index_organizations_on_activation_code"
    add_index "tiers", ["lng", "lat"], :name => "index_organizations_on_lng_and_lat"
    add_index "tiers", ["featured"], :name => "index_tiers_on_featured"
    add_index "tiers", ["twitter_name"], :name => "index_tiers_on_twitter_name"
    add_index "tiers", ["tier_category_id"], :name => "index_tiers_on_tier_category_id"
    add_index "tiers", ["language_code"], :name => "index_tiers_on_language_code"

    create_table "topics", :force => true do |t|
      t.string   "name"
      t.text     "description"
      t.string   "unit"
      t.integer  "pieces"
      t.boolean  "taxable",                          :default => true,      :null => false
      t.string   "sku_type",           :limit => 2
      t.integer  "sku_id"
      t.integer  "sku_variant_id"
      t.string   "language_code",      :limit => 2
      t.string   "country_code",       :limit => 2
      t.integer  "tier_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "status",                           :default => "passive", :null => false
      t.datetime "activated_at"
      t.boolean  "internal",                         :default => false,     :null => false
      t.string   "permalink"
      t.string   "site_url"
      t.string   "type"
      t.integer  "created_by_id"
      t.string   "activation_code",    :limit => 40
      t.datetime "deleted_at"
      t.string   "name_de"
      t.string   "description_de"
      t.string   "image_file_name"
      t.string   "image_content_type"
      t.integer  "image_file_size"
      t.datetime "image_updated_at"
      t.string   "name_es"
      t.string   "description_es"
      t.boolean  "featured",                         :default => false,     :null => false
      t.integer  "kases_count",                      :default => 0
      t.integer  "people_count",                     :default => 0
      t.string   "uuid"
    end

    add_index "topics", ["sku_id"], :name => "index_products_on_sku_id"
    add_index "topics", ["sku_type"], :name => "index_products_on_sku_type"
    add_index "topics", ["site_url"], :name => "index_products_on_site_url"
    add_index "topics", ["type"], :name => "index_products_on_type"
    add_index "topics", ["created_by_id"], :name => "index_products_on_created_by_id"
    add_index "topics", ["activation_code"], :name => "index_products_on_activation_code"
    add_index "topics", ["featured"], :name => "index_topics_on_featured"

    create_table "users", :force => true do |t|
      t.string   "salt",                      :limit => 40
      t.string   "crypted_password",          :limit => 40
      t.string   "remember_token"
      t.string   "login"
      t.string   "language",                  :limit => 2
      t.string   "currency",                  :limit => 3
      t.string   "state",                                   :default => "passive", :null => false
      t.datetime "created_at",                                                     :null => false
      t.datetime "updated_at",                                                     :null => false
      t.datetime "signed_in_at"
      t.datetime "deleted_at"
      t.datetime "activated_at"
      t.datetime "remember_token_expires_at"
      t.string   "time_zone",                               :default => ""
      t.string   "activation_code",           :limit => 40
      t.integer  "person_id"
      t.datetime "suspended_at"
    end

    add_index "users", ["login"], :name => "index_users_on_username"
    add_index "users", ["activation_code"], :name => "index_users_on_activation_code"
    add_index "users", ["person_id"], :name => "index_users_on_person_id"
    add_index "users", ["suspended_at"], :name => "index_users_on_suspended_at"

    create_table "visits", :force => true do |t|
      t.integer  "visitor_id"
      t.integer  "visited_id"
      t.string   "visited_type"
      t.datetime "created_at"
      t.string   "uuid"
      t.boolean  "unique",       :default => false, :null => false
    end

    add_index "visits", ["visitor_id"], :name => "index_visits_on_visitor_id"
    add_index "visits", ["visited_id", "visited_type"], :name => "index_visits_on_visited_id_and_visited_type"
    add_index "visits", ["uuid"], :name => "index_visits_on_uuid"
    add_index "visits", ["unique"], :name => "index_visits_on_unique"

    create_table "votes", :force => true do |t|
      t.integer  "vote"
      t.integer  "voter_id"
      t.integer  "voteable_id",   :null => false
      t.string   "voteable_type", :null => false
      t.datetime "created_at"
    end

    add_index "votes", ["voteable_id", "voteable_type"], :name => "index_votes_on_voteable_id_and_voteable_type"
    add_index "votes", ["voter_id"], :name => "index_votes_on_voter_id"

    create_table "vouchers", :force => true do |t|
      t.integer  "consignor_id"
      t.integer  "consignee_id"
      t.integer  "promotable_id"
      t.string   "promotable_type"
      t.string   "promotable_sku"
      t.string   "code"
      t.string   "uuid"
      t.string   "uuid_base"
      t.string   "email"
      t.string   "timestamp"
      t.integer  "batch"
      t.string   "mac_address"
      t.datetime "created_at"
      t.datetime "expires_at"
      t.datetime "redeemed_at"
      t.integer  "cents",                        :default => 0,     :null => false
      t.string   "currency",        :limit => 3, :default => "USD", :null => false
      t.string   "type"
    end

    add_index "vouchers", ["consignor_id"], :name => "index_vouchers_on_consignor_id"
    add_index "vouchers", ["consignee_id"], :name => "index_vouchers_on_consignee_id"
    add_index "vouchers", ["promotable_id", "promotable_type"], :name => "fk_vouchers_promotable"
    add_index "vouchers", ["code"], :name => "index_vouchers_on_code"
    add_index "vouchers", ["uuid"], :name => "index_vouchers_on_uuid"
    add_index "vouchers", ["email"], :name => "index_vouchers_on_email"
    add_index "vouchers", ["type"], :name => "index_vouchers_on_type"
  end

  def self.down
    drop_table :academic_titles
    drop_table :addresses
    drop_table :admin_users
    drop_table :assets
    drop_table :audience_types
    drop_table :bad_words
    drop_table :bids
    drop_table :cart_line_items
    drop_table :comments
    drop_table :countings
    drop_table :delayed_jobs
    drop_table :deliveries
    drop_table :deposit_accounts
    drop_table :discussion_types
    drop_table :exchange_rates
    drop_table :flags
    drop_table :follows
    drop_table :friendships
    drop_table :gateways
    drop_table :globalize_countries
    drop_table :globalize_languages
    drop_table :globalize_regions
    drop_table :globalize_translations
    drop_table :invoices
    drop_table :kases
    drop_table :kontexts
    drop_table :line_items
    drop_table :memberships
    drop_table :messages
    drop_table :offer_types
    drop_table :orders
    drop_table :outcomes
    drop_table :pages
    drop_table :payments
    drop_table :people
    drop_table :people_spoken_languages
    drop_table :personal_statuses
    drop_table :piggy_bank_account_transactions
    drop_table :piggy_bank_accounts
    drop_table :polls
    drop_table :product_lines
    drop_table :product_prices
    drop_table :products_product_prices
    drop_table :ratings
    drop_table :responses
    drop_table :rights
    drop_table :rights_roles
    drop_table :roles
    drop_table :roles_users
    drop_table :sessions
    drop_table :severities
    drop_table :spoken_languages
    drop_table :subscriptions
    drop_table :taggings
    drop_table :tags
    drop_table :tax_rates
    drop_table :tier_categories
    drop_table :tiers
    drop_table :topics
    drop_table :users
    drop_table :visits
    drop_table :votes
    drop_table :vouchers
  end
end
