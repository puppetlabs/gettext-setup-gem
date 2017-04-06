require 'rspec/expectations'
require_relative '../spec_helper.rb'

require_relative '../../lib/tasks/task_helper.rb'

describe 'string_changes?', if: msgcmp_present? do
  old_pot = File.absolute_path('../fixtures/pot_update/old.pot', File.dirname(__FILE__))

  it 'should detect string addition' do
    new_pot = File.absolute_path('../fixtures/pot_update/add.pot', File.dirname(__FILE__))
    expect(string_changes?(old_pot, new_pot)).to eq(true)
  end

  it 'should detect string removal' do
    new_pot = File.absolute_path('../fixtures/pot_update/remove.pot', File.dirname(__FILE__))
    expect(string_changes?(old_pot, new_pot)).to eq(true)
  end

  it 'should detect string changes' do
    new_pot = File.absolute_path('../fixtures/pot_update/change.pot', File.dirname(__FILE__))
    expect(string_changes?(old_pot, new_pot)).to eq(true)
  end

  it 'should not detect non-string changes' do
    new_pot = File.absolute_path('../fixtures/pot_update/non_string_changes.pot', File.dirname(__FILE__))
    expect(string_changes?(old_pot, new_pot)).to eq(false)
  end
end
