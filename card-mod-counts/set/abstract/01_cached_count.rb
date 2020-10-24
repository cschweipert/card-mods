# -*- encoding : utf-8 -*-

# Cards in this set cache a count in the counts table

include_set Abstract::BsBadge

def self.included host_class
  host_class.extend ClassMethods
  # host_class.card_writer :cached_count, type: :plain_text
  host_class
end

def cached_count
  @cached_count || hard_cached_count(::Count.fetch_value(self))
end

def update_cached_count _changed_card=nil
  hard_cached_count ::Count.refresh(self)
end

def hard_cached_count value
  Card.cache.hard&.write_attribute key, :cached_count, value
  @cached_count = value
end

# called to refresh the cached count
# the default way is that the card is a search card and we just
# count the search result
# for special calculations override this method in your set
def recount
  count
end

module ClassMethods
  def recount_trigger *set_parts_of_changed_card
    args =
      set_parts_of_changed_card.last.is_a?(Hash) ? set_parts_of_changed_card.pop : {}
    set_of_changed_card = ensure_set { set_parts_of_changed_card }
    # args[:on] ||= [:create, :update, :delete]
    name = event_name set_of_changed_card, args
    set_of_changed_card.class_eval do
      event name, :after_integrate, args do
        # , args.merge(after_all: :refresh_updated_answers) do
        Array.wrap(yield(self)).compact.each do |expired_count_card|
          next unless expired_count_card.respond_to?(:recount)
          expired_count_card.update_cached_count self
        end
      end
    end
  end

  def event_name set, args
    changed_card_set = set.to_s.tr(":", "_").underscore
    cached_count_set = to_s.tr(":", "_").underscore
    actions = Array.wrap args[:on]
    "update_cached_count_for_#{cached_count_set}_due_to_change_in_" \
        "#{changed_card_set}_on_#{actions.join('_')}".to_sym
  end
end

format do
  def count
    card.cached_count
  end
end
