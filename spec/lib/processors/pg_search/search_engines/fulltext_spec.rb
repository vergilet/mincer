require 'spec_helper'

describe ::Mincer::PgSearch::SearchEngines::Fulltext do
  before do
    setup_postgres_table
  end
  subject(:search_engine_class) { ::Mincer::PgSearch::SearchEngines::Fulltext }
  let(:search_statement_class) { ::Mincer::Processors::PgSearch::SearchStatement }

  describe '.search_engine_statements' do
    context 'when 2 columns' do
      it 'stores them in instance variable hash under :or key' do
        search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext])
        search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:fulltext])
        search_engine = search_engine_class.new('search', [search_statement1, search_statement2])
        search_engine.send(:search_engine_statements).should include(search_statement1)
        search_engine.send(:search_engine_statements).should include(search_statement2)
      end
    end

    it 'ignores other engines' do
      search_statement1 = search_statement_class.new(['"records"."text"'])
      search_statement2 = search_statement_class.new(['"records"."text2"'], engines: [:array])
      search_engine = search_engine_class.new('search', [search_statement1, search_statement2])
      search_engine.send(:search_engine_statements).should == []
      search_engine.send(:search_engine_statements).should == []
    end
  end

  describe '.conditions' do
    it 'generates search condition with one column, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext])
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.should == %{(((to_tsvector('simple', "records"."text")) @@ (to_tsquery('simple', concat('search')))))}
    end

    it 'generates search condition with two columns, one term and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext])
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.should == %{(((to_tsvector('simple', "records"."text") || to_tsvector('simple', "records"."text2")) @@ (to_tsquery('simple', concat('search')))))}
    end

    it 'generates search condition with two columns, two terms and no options' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext])
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.should == %{(((to_tsvector('simple', "records"."text") || to_tsvector('simple', "records"."text2")) @@ (to_tsquery('simple', concat('search') || ' & ' || concat('word')))))}
    end

    it 'generates search condition with two columns, two terms and option "any_word" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext], any_word: true)
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.should == %{(((to_tsvector('simple', "records"."text") || to_tsvector('simple', "records"."text2")) @@ (to_tsquery('simple', concat('search') || ' | ' || concat('word')))))}
    end

    it 'generates search condition with two columns, two terms and option "ignore_accent" set to true ' do
      search_statement1 = search_statement_class.new(['"records"."text"', '"records"."text2"'], engines: [:fulltext], ignore_accent: true)
      search_engine = search_engine_class.new('search word', [search_statement1])
      search_engine.conditions.should == %{(((to_tsvector('simple', unaccent("records"."text")) || to_tsvector('simple', unaccent("records"."text2"))) @@ (to_tsquery('simple', unaccent(concat('search')) || ' & ' || unaccent(concat('word'))))))}
    end

    it 'generates search condition with one column, one term and option "dictionary" set to :english' do
      search_statement1 = search_statement_class.new(['"records"."text"'], engines: [:fulltext], dictionary: :english)
      search_engine = search_engine_class.new('search', [search_statement1])
      search_engine.conditions.should == %{(((to_tsvector('english', "records"."text")) @@ (to_tsquery('english', concat('search')))))}
    end

  end

end
