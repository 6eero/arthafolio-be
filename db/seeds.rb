if Rails.env.developmentt?
  puts '🌱 Seeding development database...'

  # Pulizia dati
  PortfolioSnapshot.destroy_all
  Holding.destroy_all
  Price.destroy_all
  User.destroy_all

  # Crea l'utente demo
  user = User.create!(
    username: 'demo',
    email: 'demo@arthafolio.com',
    password: 'password123',
    password_confirmation: 'password123'
  )

  # Inserimento dati di portfolio_snapshot associati all'utente appena creato
  portfolio_snapshots_data = [
    { id: 375, total_value: 116_663.0774163342, taken_at: '2025-07-18 21:00:06.457000' },
    { id: 377, total_value: 116_843.9056346743, taken_at: '2025-07-18 22:00:07.304859' },
    { id: 379, total_value: 116_892.4844111382, taken_at: '2025-07-18 23:00:07.491387' },
    { id: 381, total_value: 116_955.7950785125, taken_at: '2025-07-19 00:00:08.563806' },
    { id: 383, total_value: 116_968.623190772, taken_at: '2025-07-19 01:00:08.414339' },
    { id: 385, total_value: 116_942.9818820464, taken_at: '2025-07-19 02:00:08.489704' },
    { id: 387, total_value: 116_912.8687702473, taken_at: '2025-07-19 03:00:06.963496' },
    { id: 389, total_value: 117_130.6384232314, taken_at: '2025-07-19 04:00:07.471549' },
    { id: 391, total_value: 117_215.1729447478, taken_at: '2025-07-19 05:00:06.944208' },
    { id: 393, total_value: 117_219.8247071686, taken_at: '2025-07-19 06:00:07.240742' },
    { id: 395, total_value: 117_329.8378378378, taken_at: '2025-07-19 07:00:08.452636' },
    { id: 397, total_value: 117_347.1190282496, taken_at: '2025-07-19 08:00:07.721469' },
    { id: 399, total_value: 117_424.1678229729, taken_at: '2025-07-19 09:00:07.489434' },
    { id: 401, total_value: 117_366.4293079975, taken_at: '2025-07-19 10:00:07.619025' },
    { id: 403, total_value: 117_417.8920117904, taken_at: '2025-07-19 11:00:07.135272' },
    { id: 405, total_value: 117_498.4358872588, taken_at: '2025-07-19 12:00:07.037191' },
    { id: 407, total_value: 117_493.5960011581, taken_at: '2025-07-19 13:00:07.086301' },
    { id: 409, total_value: 117_585.1105470798, taken_at: '2025-07-19 14:00:07.834035' },
    { id: 411, total_value: 117_621.5790449646, taken_at: '2025-07-19 15:00:07.271966' },
    { id: 413, total_value: 117_688.0435198909, taken_at: '2025-07-19 16:00:07.669896' },
    { id: 415, total_value: 117_812.5691060636, taken_at: '2025-07-19 17:00:07.362678' },
    { id: 417, total_value: 117_831.6253457905, taken_at: '2025-07-19 18:00:06.918991' },
    { id: 419, total_value: 117_878.5085188835, taken_at: '2025-07-19 19:00:06.983995' },
    { id: 421, total_value: 117_849.658253162, taken_at: '2025-07-19 20:00:07.494791' },
    { id: 423, total_value: 118_029.0718536647, taken_at: '2025-07-19 21:00:07.107052' },
    { id: 425, total_value: 118_005.474668471, taken_at: '2025-07-19 22:00:07.668541' },
    { id: 427, total_value: 117_978.9669654013, taken_at: '2025-07-19 23:00:07.828882' },
    { id: 429, total_value: 117_872.4835695015, taken_at: '2025-07-20 00:00:08.204555' },
    { id: 431, total_value: 117_869.6974288075, taken_at: '2025-07-20 01:00:07.876353' },
    { id: 433, total_value: 117_929.5843478905, taken_at: '2025-07-20 02:00:08.575024' },
    { id: 435, total_value: 117_967.8931505342, taken_at: '2025-07-20 03:00:07.818809' },
    { id: 437, total_value: 117_921.2291589139, taken_at: '2025-07-20 04:00:08.068228' },
    { id: 439, total_value: 117_937.6046182247, taken_at: '2025-07-20 05:00:08.093498' },
    { id: 441, total_value: 117_887.6521360094, taken_at: '2025-07-20 06:00:08.232398' },
    { id: 443, total_value: 117_800.749005995, taken_at: '2025-07-20 07:00:07.989711' },
    { id: 445, total_value: 117_769.721245037, taken_at: '2025-07-20 08:00:07.858216' },
    { id: 447, total_value: 117_805.1390142093, taken_at: '2025-07-20 09:00:08.644159' },
    { id: 449, total_value: 117_815.9035669206, taken_at: '2025-07-20 10:00:07.825357' },
    { id: 451, total_value: 117_820.6227398974, taken_at: '2025-07-20 11:00:09.275789' }
  ]

  portfolio_snapshots_data.each do |snapshot|
    PortfolioSnapshot.create!(
      id: snapshot[:id],
      user_id: user.id,
      total_value: snapshot[:total_value],
      taken_at: snapshot[:taken_at],
      created_at: snapshot[:taken_at],
      updated_at: snapshot[:taken_at]
    )
  end

  puts '✅ Seed completed!'
end
