# -*- encoding : utf-8 -*-

class AddLatexScriptCard < Card::Migration::Core
  def up
    ensure_card "script: latex", type_id: Card::CoffeeScriptID,
                                 codename: "script_latex"
  end
end
