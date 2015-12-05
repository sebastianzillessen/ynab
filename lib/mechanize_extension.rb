module MechanizeExtension
  module Mechanize
    module Form
      def select_with(args={})
        self.selects_with(args).first
      end

      def selects_with(args={})
        self.fields_with(args).select { |t| t.is_a? self.class::SelectList }
      end
    end
  end
end
Mechanize::Form.include(MechanizeExtension::Mechanize::Form)