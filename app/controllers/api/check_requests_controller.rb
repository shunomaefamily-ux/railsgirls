class Api::CheckRequestsController < ApplicationController
  def current
    render json: {
      check_request: {
        id: 1,
        title: "朝の服薬確認",
        person_name: "田中太郎",
        scheduled_at: "09:00",
        items: [
          { name: "ロキソニン", dose_amount: "1", dose_unit: "錠" }
        ]
      }
    }
  end
end