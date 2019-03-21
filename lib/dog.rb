require "pry"

class Dog
  attr_accessor :name, :breed
  attr_reader :id

  def initialize(id: nil, name:, breed:)
    @name = name
    @breed = breed
    @id = id
  end

  def self.create_table
    sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
          id INTEGER PRIMARY KEY,
          name TEXT,
          breed TEXT
        );
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
    DROP TABLE IF  EXISTS dogs;
    SQL
    DB[:conn].execute(sql)
  end

  def update
    sql = <<-SQL
      UPDATE dogs SET name = ?, breed = ? WHERE id = ?
    SQL
    DB[:conn].execute(sql, @name, @breed, @id)
  end

  def save
    if @id
      @update
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed) VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, @name, @breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    end
    self
  end

  def self.create(name:, breed:)
    doggo = Dog.new(name: name, breed: breed)
    doggo.save
    doggo
  end

  def self.new_from_db(row)
    id = row[0]
    name = row[1]
    breed = row[2]
    Dog.new(id: id, name: name, breed: breed)
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs WHERE name = ? LIMIT 1
    SQL
    DB[:conn].execute(sql, name).map do |row|
      self.new_from_db(row)
    end.first
  end

  def self.find_by_id(id)
    sql = <<-SQL
    SELECT * FROM dogs WHERE id = ? LIMIT 1
    SQL
    DB[:conn].execute(sql, id).map do |row|
      Dog.new_from_db(row)
    end.first
  end

  def self.find_or_create_by(name:, breed:)
    sql = <<-SQL
      SELECT * FROM dogs WHERE name = ? AND breed = ? LIMIT 1
    SQL

    doggo = DB[:conn].execute(sql, name, breed)
    if doggo.empty?
      doggo = Dog.create(name: name, breed: breed)
    else
      doggo = Dog.new(id: doggo[0][0], name: doggo[0][1], breed: doggo[0][2])
    end
    doggo
  end
end
