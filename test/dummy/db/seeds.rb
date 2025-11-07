# frozen_string_literal: true

# Clear existing data
puts "🗑️  Nettoyage des données existantes..."
[ Address, Comment, Profile, Post, Category, Tag, User ].each do |model|
  model.destroy_all
end

puts "🌱 Début du seeding..."

# ============================================================================
# CATEGORIES
# ============================================================================
puts "\n📁 Création des catégories..."

categories_data = [
  { name: "Technologie", description: "Tout sur la tech, le développement et l'innovation", position: 1, visible: true },
  { name: "Lifestyle", description: "Vie quotidienne, santé et bien-être", position: 2, visible: true },
  { name: "Business", description: "Entrepreneuriat, management et finance", position: 3, visible: true },
  { name: "Voyage", description: "Destinations, conseils et récits de voyage", position: 4, visible: true },
  { name: "Cuisine", description: "Recettes, astuces et culture culinaire", position: 5, visible: true },
  { name: "Sport", description: "Activités sportives, fitness et compétitions", position: 6, visible: true },
  { name: "Culture", description: "Art, littérature, cinéma et musique", position: 7, visible: true },
  { name: "Science", description: "Découvertes scientifiques et innovations", position: 8, visible: true },
  { name: "Archive", description: "Anciens articles archivés", position: 99, visible: false }
]

categories = categories_data.map do |data|
  category = Category.create!(data)
  puts "  ✓ #{category.name}"
  category
end

# ============================================================================
# TAGS
# ============================================================================
puts "\n🏷️  Création des tags..."

tags_data = [
  { name: "ruby", color: "#CC342D" },
  { name: "rails", color: "#CC0000" },
  { name: "javascript", color: "#F7DF1E" },
  { name: "typescript", color: "#3178C6" },
  { name: "python", color: "#3776AB" },
  { name: "react", color: "#61DAFB" },
  { name: "vue", color: "#4FC08D" },
  { name: "angular", color: "#DD0031" },
  { name: "nodejs", color: "#339933" },
  { name: "tutorial", color: "#007ACC" },
  { name: "débutant", color: "#28A745" },
  { name: "avancé", color: "#DC3545" },
  { name: "devops", color: "#326CE5" },
  { name: "sécurité", color: "#FF6B6B" },
  { name: "performance", color: "#FFA500" },
  { name: "design", color: "#E91E63" },
  { name: "mobile", color: "#9C27B0" },
  { name: "web", color: "#00BCD4" },
  { name: "cloud", color: "#607D8B" },
  { name: "ia", color: "#FF5722" }
]

tags = tags_data.map do |data|
  tag = Tag.create!(data)
  puts "  ✓ #{tag.name}"
  tag
end

# ============================================================================
# USERS
# ============================================================================
puts "\n👥 Création des utilisateurs..."

# Admin
admin = User.create!(
  name: "Admin SuperUser",
  email: "admin@example.com",
  role: :admin,
  active: true
)
puts "  ✓ #{admin.name} (#{admin.role})"

# Moderators
moderators = [
  { name: "Sophie Martin", email: "sophie.martin@example.com" },
  { name: "Thomas Dubois", email: "thomas.dubois@example.com" }
].map do |data|
  user = User.create!(data.merge(role: :moderator, active: true))
  puts "  ✓ #{user.name} (#{user.role})"
  user
end

# Regular users
users = [
  { name: "Marie Lefebvre", email: "marie.lefebvre@example.com" },
  { name: "Pierre Durand", email: "pierre.durand@example.com" },
  { name: "Julie Moreau", email: "julie.moreau@example.com" },
  { name: "Laurent Simon", email: "laurent.simon@example.com" },
  { name: "Isabelle Bernard", email: "isabelle.bernard@example.com" },
  { name: "Nicolas Petit", email: "nicolas.petit@example.com" },
  { name: "Catherine Robert", email: "catherine.robert@example.com" },
  { name: "Alexandre Richard", email: "alexandre.richard@example.com" },
  { name: "Céline Dumont", email: "celine.dumont@example.com" },
  { name: "Julien Lambert", email: "julien.lambert@example.com" }
].map do |data|
  user = User.create!(data.merge(role: :user, active: true))
  puts "  ✓ #{user.name} (#{user.role})"
  user
end

# Inactive user
inactive_user = User.create!(
  name: "Ancien Utilisateur",
  email: "ancien@example.com",
  role: :user,
  active: false
)
puts "  ✓ #{inactive_user.name} (inactif)"

all_users = [ admin ] + moderators + users
active_users = all_users

# ============================================================================
# PROFILES
# ============================================================================
puts "\n👤 Création des profils utilisateurs..."

timezones = [ "Europe/Paris", "America/New_York", "Asia/Tokyo", "Europe/London", "America/Los_Angeles" ]
themes = [ "light", "dark", "auto" ]
languages = [ "fr", "en", "es" ]

all_users.each do |user|
  birth_year = rand(25..50)
  Profile.create!(
    user: user,
    avatar_url: "https://i.pravatar.cc/150?u=#{user.email}",
    bio: "Passionné(e) de #{[ 'technologie', 'innovation', 'développement', 'design', 'entrepreneuriat' ].sample}. #{[ 'Développeur', 'Designer', 'Manager', 'Consultant', 'Entrepreneur' ].sample} depuis #{rand(3..15)} ans.",
    birth_date: birth_year.years.ago.to_date,
    preferred_notification_time: Time.parse("#{rand(8..10)}:#{[ '00', '30' ].sample}"),
    rating: rand(3.0..5.0).round(2),
    preferences: {
      theme: themes.sample,
      language: languages.sample,
      items_per_page: [ 10, 25, 50, 100 ].sample
    },
    social_links: {
      twitter: "@#{user.name.parameterize}",
      github: user.name.parameterize,
      linkedin: user.name.parameterize
    },
    phone_number: "+33 #{rand(1..9)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)}",
    website: "https://#{user.name.parameterize}.dev",
    timezone: timezones.sample,
    notification_frequency: [ :daily, :weekly, :real_time ].sample,
    email_notifications: [ true, true, true, false ].sample,
    sms_notifications: [ true, false, false, false ].sample
  )
  puts "  ✓ Profil de #{user.name}"
end

# ============================================================================
# ADDRESSES
# ============================================================================
puts "\n🏠 Création des adresses..."

cities = [
  { name: "Paris", lat: 48.8566, lon: 2.3522, postal_code: "75001" },
  { name: "Lyon", lat: 45.7640, lon: 4.8357, postal_code: "69001" },
  { name: "Marseille", lat: 43.2965, lon: 5.3698, postal_code: "13001" },
  { name: "Toulouse", lat: 43.6047, lon: 1.4442, postal_code: "31000" },
  { name: "Nice", lat: 43.7102, lon: 7.2620, postal_code: "06000" },
  { name: "Nantes", lat: 47.2184, lon: -1.5536, postal_code: "44000" },
  { name: "Bordeaux", lat: 44.8378, lon: -0.5792, postal_code: "33000" },
  { name: "Lille", lat: 50.6292, lon: 3.0573, postal_code: "59000" }
]

address_count = 0
all_users.each do |user|
  num_addresses = rand(1..3)
  num_addresses.times do |i|
    city = cities.sample
    Address.create!(
      user: user,
      address_type: [ :home, :work, :billing, :shipping ].sample,
      street_line1: "#{rand(1..200)} rue #{[ 'de la Paix', 'Victor Hugo', 'Voltaire', 'Jean Jaurès', 'des Fleurs' ].sample}",
      street_line2: i.zero? ? nil : [ "Appartement #{rand(1..50)}", "Bâtiment #{('A'..'C').to_a.sample}" ].sample,
      city: city[:name],
      state: [ "Île-de-France", "Auvergne-Rhône-Alpes", "Provence-Alpes-Côte d'Azur", "Occitanie", "Nouvelle-Aquitaine" ].sample,
      postal_code: city[:postal_code],
      country: "France",
      is_primary: i.zero?,
      latitude: city[:lat] + rand(-0.1..0.1).round(6),
      longitude: city[:lon] + rand(-0.1..0.1).round(6)
    )
    address_count += 1
  end
end
puts "  ✓ #{address_count} adresses créées"

# ============================================================================
# POSTS
# ============================================================================
puts "\n📝 Création des articles..."

post_titles = {
  "Technologie" => [
    "Introduction à Ruby on Rails pour débutants",
    "Les meilleures pratiques de développement web en 2025",
    "Comment optimiser les performances de votre application Rails",
    "Guide complet du testing avec RSpec",
    "Architecture microservices avec Rails",
    "Les nouveautés de Ruby 3.3",
    "Sécuriser votre application Rails : guide complet",
    "API REST vs GraphQL : quel choix faire ?"
  ],
  "Lifestyle" => [
    "10 habitudes pour améliorer votre productivité",
    "L'équilibre vie professionnelle / vie personnelle",
    "Méditation et développement personnel",
    "Comment bien commencer sa journée",
    "Les bienfaits du sport sur le mental"
  ],
  "Business" => [
    "Lancer sa startup : les étapes clés",
    "Le management à distance : défis et opportunités",
    "Stratégies de croissance pour les PME",
    "Finance pour entrepreneurs débutants",
    "Marketing digital : tendances 2025"
  ],
  "Voyage" => [
    "Top 10 des destinations européennes",
    "Voyager en solo : conseils et astuces",
    "Budget voyage : comment économiser",
    "Les plus belles plages du monde"
  ],
  "Cuisine" => [
    "Recettes végétariennes faciles et rapides",
    "La cuisine française pour débutants",
    "Batch cooking : préparer ses repas de la semaine",
    "Les secrets d'un bon pain maison"
  ],
  "Sport" => [
    "Programme de musculation pour débutants",
    "Course à pied : éviter les blessures",
    "Yoga : bienfaits et postures essentielles",
    "Nutrition sportive : les bases"
  ],
  "Culture" => [
    "Les films incontournables de 2025",
    "Histoire de l'art moderne",
    "Littérature française contemporaine",
    "La révolution du streaming musical"
  ],
  "Science" => [
    "L'intelligence artificielle expliquée simplement",
    "Changement climatique : état des lieux",
    "Les dernières découvertes en astrophysique",
    "Biotechnologie et médecine du futur"
  ]
}

statuses = [ :draft, :published, :published, :published, :archived ]
post_count = 0

categories.each do |category|
  next unless post_titles[category.name]

  titles = post_titles[category.name]
  titles.each do |title|
    author = active_users.sample
    status = statuses.sample

    # Generate realistic body content
    paragraphs = rand(5..12)
    body_parts = []
    paragraphs.times do
      sentences = rand(3..7)
      paragraph = []
      sentences.times do
        paragraph << "Lorem ipsum dolor sit amet, consectetur adipiscing elit. #{[ 'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.', 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore.', 'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.' ].sample}"
      end
      body_parts << paragraph.join(" ")
    end
    body = body_parts.join("\n\n")

    published_at = case status
    when :published then rand(60.days.ago..Time.current)
    when :archived then rand(365.days.ago..60.days.ago)
    else nil
    end

    post = Post.create!(
      user: author,
      category: category,
      title: title,
      body: body,
      status: status,
      published_at: published_at,
      view_count: status == :published ? rand(10..1000) : 0,
      featured: status == :published && rand < 0.2,
      metadata: {
        seo_title: "#{title} - Guide Complet",
        seo_description: body_parts.first.truncate(160),
        author_notes: [ "Article approfondi", "Recherche extensive", "Exemples pratiques", "Tutoriel complet" ].sample
      }
    )

    # Add random tags (2-5 per post)
    post.tags << tags.sample(rand(2..5))

    post_count += 1
    print "  ✓ Article #{post_count}: #{title.truncate(50)}\n"
  end
end

# ============================================================================
# COMMENTS
# ============================================================================
puts "\n💬 Création des commentaires..."

positive_comments = [
  "Excellent article, très instructif !",
  "Merci pour ces explications claires.",
  "Super contenu, j'ai beaucoup appris.",
  "Très intéressant, continue comme ça !",
  "Article de qualité, merci du partage.",
  "Exactement ce que je cherchais !",
  "Bravo pour ce travail de recherche.",
  "Très bien expliqué, merci !",
  "Content de voir ce type de contenu.",
  "Article complet et bien structuré."
]

neutral_comments = [
  "Intéressant, mais j'aurais aimé plus de détails sur certains points.",
  "Bon article dans l'ensemble.",
  "Quelques informations utiles.",
  "Merci pour le partage.",
  "Pas mal, mais on a déjà vu mieux.",
  "Article correct.",
  "Certains points auraient mérité d'être développés."
]

negative_comments = [
  "Je ne suis pas d'accord avec certains points.",
  "L'article manque de profondeur.",
  "Sources peu fiables à mon avis.",
  "Trop superficiel pour être vraiment utile.",
  "On a déjà lu ça ailleurs."
]

spam_comments = [
  "Visit my website for amazing deals!!!",
  "Buy cheap products now!!!",
  "Click here for free stuff",
  "Make money fast with this trick"
]

comment_count = 0
Post.published.each do |post|
  num_comments = rand(0..8)

  num_comments.times do
    commenter = active_users.sample

    # Déterminer le type de commentaire
    comment_type = rand
    content, status, approved_at = if comment_type < 0.7
                                     [ positive_comments.sample, :approved, rand(1.hour.ago..Time.current) ]
    elsif comment_type < 0.85
                                     [ neutral_comments.sample, :approved, rand(1.hour.ago..Time.current) ]
    elsif comment_type < 0.92
                                     [ negative_comments.sample, rand < 0.7 ? :approved : :rejected, rand < 0.7 ? rand(1.hour.ago..Time.current) : nil ]
    elsif comment_type < 0.97
                                     [ positive_comments.sample, :pending, nil ]
    else
                                     [ spam_comments.sample, :spam, nil ]
    end

    Comment.create!(
      commentable: post,
      user: commenter,
      content: content,
      status: status,
      likes_count: status == :approved ? rand(0..50) : 0,
      approved_at: approved_at,
      ip_address: "192.168.#{rand(1..255)}.#{rand(1..255)}"
    )
    comment_count += 1
  end
end
puts "  ✓ #{comment_count} commentaires créés"

# ============================================================================
# UPDATE COUNTER CACHES
# ============================================================================
puts "\n🔄 Mise à jour des compteurs..."

User.find_each do |user|
  User.reset_counters(user.id, :posts, :comments)
end

Category.find_each do |category|
  Category.reset_counters(category.id, :posts)
end

Tag.find_each do |tag|
  tag.update!(usage_count: tag.posts.count)
end

# ============================================================================
# STATISTICS
# ============================================================================
puts "\n" + "=" * 70
puts "✨ SEEDING TERMINÉ AVEC SUCCÈS !"
puts "=" * 70
puts "\n📊 STATISTIQUES :\n\n"
puts "  👥 Utilisateurs     : #{User.count} (#{User.where(role: :admin).count} admin, #{User.where(role: :moderator).count} moderators, #{User.where(role: :user).count} users)"
puts "  📝 Articles         : #{Post.count} (#{Post.published.count} publiés, #{Post.where(status: :draft).count} brouillons, #{Post.where(status: :archived).count} archivés)"
puts "  📁 Catégories       : #{Category.count} (#{Category.visible.count} visibles)"
puts "  🏷️  Tags            : #{Tag.count}"
puts "  💬 Commentaires     : #{Comment.count} (#{Comment.approved.count} approuvés, #{Comment.pending_review.count} en attente, #{Comment.where(status: :spam).count} spam)"
puts "  👤 Profils          : #{Profile.count}"
puts "  🏠 Adresses         : #{Address.count}"
puts "\n📈 STATISTIQUES DÉTAILLÉES :\n\n"
puts "  ⭐ Articles vedettes      : #{Post.featured.count}"
puts "  👀 Vues totales           : #{Post.sum(:view_count)}"
puts "  💚 Likes sur commentaires : #{Comment.sum(:likes_count)}"
puts "  📍 Adresses principales   : #{Address.where(is_primary: true).count}"
puts "  📧 Notifications activées : #{Profile.where(email_notifications: true).count}"
puts "\n🎯 TOP CONTRIBUTEURS :\n\n"

User.joins(:posts).group("users.id").order("COUNT(posts.id) DESC").limit(5).each_with_index do |user, index|
  posts_count = user.posts.count
  comments_count = user.comments.count
  puts "  #{index + 1}. #{user.name.ljust(25)} - #{posts_count} articles, #{comments_count} commentaires"
end

puts "\n🏆 CATÉGORIES POPULAIRES :\n\n"

Category.joins(:posts).group("categories.id").order("COUNT(posts.id) DESC").limit(5).each_with_index do |category, index|
  posts_count = category.posts.count
  puts "  #{index + 1}. #{category.name.ljust(20)} - #{posts_count} articles"
end

puts "\n" + "=" * 70
puts "✅ Vous pouvez maintenant explorer l'application avec des données réalistes !"
puts "=" * 70
puts "\n"
