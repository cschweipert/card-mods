def save_session_votes
  [:up_vote, :down_vote].each do |vote_type|
    next unless Env.session[vote_type]
    Env.session[vote_type].each do |votee_id|
      if (votee = Card.fetch(votee_id))
        update_vote votee, vote_type
      end
    end
    Env.session.delete(vote_type)
  end
end

def vote_key card_id=id
  "~#{card_id}"
end

def vote_status
  if Auth.signed_in?
    Auth.current&.respond_to?(:upvotes_card) ? signed_in_vote_status : :no_vote
  elsif try(:session_vote?)
    session_vote_status
  else
    :no_vote
  end
end

def signed_in_vote_status
  [:up, :down].each do |dir|
    return "#{dir}voted".to_sym if voted? Auth.current, dir
  end
  :no_vote
end

def voted? user_card, direction
  vote_pointer = user_card.send "#{direction}votes_card"
  vote_pointer.item_strings.include? "[[#{vote_key}]]"
end

def session_vote_status
  if upvoted_in_session?
    :upvoted
  elsif downvoted_in_session?
    :downvoted
  else
    :no_vote
  end
end

def update_vote votee, vote_type
  vote_card = votee.vote_count_card
  case vote_type
  when :up_vote
    vote_card.force_up
  when :down_vote
    vote_card.force_down
  end
  vote_card.save!
end

format :html do
  view :titled_with_voting do
    @content_body = true
    voo.hide :menu
    wrap do
      [
        _render_menu,
        nest(card.vote_count_card, view: :content),
        render!(:header),
        wrap_body { _render_core },
        render(:comment_box)
      ]
    end
  end

  view :header_with_voting do
    haml do
      <<-HAML
.header-with-vote
  .header-vote
    = subformat( card.vote_count_card ).render_details
  .header-title
    = render!(:header)
    .creator-credit
      = process_content "{{_self | structure:creator credit}}"
.clear-line
      HAML
    end
  end
end

def downvoted_in_session?
  Env.session[:down_vote] && Env.session[:down_vote].include?(id)
end

def upvoted_in_session?
  Env.session[:up_vote] && Env.session[:up_vote].include?(id)
end
