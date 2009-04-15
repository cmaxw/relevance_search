class << ActiveRecord::Base
  def relevance_search_attributes(attrs)
    @relevance_search_attributes = attrs || []
  end

  def relevance_search(term)
    if @relevance_search_attributes.nil?
      search_attributes = self.new.attribute_names
    else
      search_attributes = @relevance_search_attributes
    end
    db_conf = YAML.load_file(File.join(File.dirname(__FILE__), '/../../../../config/database.yml'))[ENV['RAILS_ENV']]
    temp_db = establish_connection(db_conf).connection
    temp_db.begin_db_transaction
    temp_db.execute "CREATE TEMPORARY TABLE temp_table (id int);"
    search_attributes.each do |attr|
      temp_db.execute "INSERT INTO temp_table (id) SELECT id FROM #{table_name} WHERE #{attr} like '%#{term}%';"
    end
    temp_db.commit_db_transaction

    query_results = temp_db.select_all("SELECT id FROM temp_table GROUP BY id ORDER BY COUNT(*) DESC, id ASC;")
    results = []
    query_results.each {|row| results << find_by_id(row['id'])}
    temp_db.execute "DROP TABLE temp_table;"

    results
  end
end

class ActiveRecord::Base
  def relevance(term)
    if @relevance_search_attributes.nil?
      search_attributes = self.new.attribute_names
    else
      search_attributes = @relevance_search_attributes
    end
    rel = 0
    search_attributes.each {|attr| rel += 1 if eval("#{attr}.to_s.include?(term)")}
  end
end

