# db/seeds.rb

puts "--- Seeding Database for Ekklesia SGEI ---"

# 1. Church
puts "Creating Church..."
church = Church.find_or_create_by!(slug: "ekklesia") do |c|
  c.name = "Ekklesia Comunidade Cristã"
  c.email = "contato@ekklesia.org"
  c.phone = "+55 11 98765-4321"
end

# 2. Departments
puts "Creating Departments..."
departments_data = [
  { name: "Louvor & Adoração", description: "Ministério de música e artes" },
  { name: "Kids & Teens", description: "Educação cristã para crianças e adolescentes" },
  { name: "Missões & Social", description: "Ações evangelísticas e suporte social" },
  { name: "Mídia & Tecnologia", description: "Transmissão, redes sociais e suporte técnico" },
  { name: "Administrativo", description: "Gestão financeira e operacional" }
]

departments = departments_data.map do |dept_data|
  church.departaments.find_or_create_by!(name: dept_data[:name]) do |d|
    d.description = dept_data[:description]
  end
end

# 3. Users
puts "Creating Users..."
# Admin (System Owner)
admin = User.find_or_create_by!(email: "jonatas@ekklesia.org") do |u|
  u.name = "Jonatas Venancio"
  u.phone = "(11) 98765-4321"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :admin
  u.church = church
  u.status = :active
end

# Leader
leader = User.find_or_create_by!(email: "ana.louvor@ekklesia.org") do |u|
  u.name = "Ana Louvor"
  u.phone = "(11) 98765-1234"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :leader
  u.church = church
  u.status = :active
end

# Member
member = User.find_or_create_by!(email: "membro@example.com") do |u|
  u.name = "Membro Visitante"
  u.phone = "(11) 98765-5678"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :member
  u.church = church
  u.status = :active
end

# Birth dates relative to today so the birthdays page always shows data
puts "Setting birth dates..."
{
  admin  => Date.current - 34.years,               # aniversário hoje
  leader => (Date.current + 3.days) - 28.years,    # aniversário em 3 dias
  member => Date.current.change(day: 25) - 22.years
}.each do |user, birth_date|
  user.update!(birth_date: birth_date) if user.birth_date.blank?
end

# Welcome records (acolhimento) — some today, some in the past
puts "Creating Welcome Records..."
[
  { name: "Maria Souza",  visitor_type: :visitor, city: "Fortaleza",  service: WelcomeRecord::SERVICES.first,
    phone: "(85) 98888-1111", notes: "Primeira visita, veio com a família.", created_at: Time.current },
  { name: "Pedro Lima",   visitor_type: :brother, congregation: "Igreja da Paz", city: "Maracanaú",
    service: WelcomeRecord::SERVICES.first, created_at: Time.current },
  { name: "Carla Mendes", visitor_type: :visitor, city: "Caucaia", service: WelcomeRecord::SERVICES.second,
    phone: "(85) 97777-2222", became_member: true, created_at: 2.weeks.ago },
  { name: "João Batista", visitor_type: :brother, congregation: "Assembleia Central", city: "Fortaleza",
    service: WelcomeRecord::SERVICES.third, created_at: 1.month.ago }
].each do |attrs|
  church.welcome_records.find_or_create_by!(name: attrs[:name]) do |record|
    record.assign_attributes(attrs.merge(registered_by: admin))
  end
end

# 4. Memberships (Memberchips)
puts "Creating Memberships..."
# Ana is leader of Louvor (index 0)
Memberchip.find_or_create_by!(user: leader, departament: departments[0]) do |m|
  m.role = 1 # Assuming 1 is a leader role within the department
end

# 5. Events
puts "Creating Initial Event..."
event = Event.find_or_create_by!(slug: "noite-de-adoracao-2026") do |e|
  e.church = church
  e.departament = departments[0]
  e.title = "Noite de Adoração: Ekklesia 2026"
  e.description = "Uma noite dedicada ao louvor e à comunhão profunda com o Criador."
  e.location = "Sede Principal"
  e.start_date = Date.today + 30
  e.end_date = Date.today + 30
  e.created_by_id = admin.id
  e.visibility = :public_event
end

# 6. Forms
puts "Creating Registration Form..."
form = Form.find_or_create_by!(church: church, event: event) do |f|
  f.title = "Check-in Noite de Adoração"
  f.description = "Confirme sua presença para nos ajudar na organização."
  f.active = true
end

# 7. Form Fields
puts "Creating Form Fields..."
fields = [
  { label: "Nome Completo", type: "text", required: true, pos: 1 },
  { label: "Possui restrição alimentar?", type: "text", required: false, pos: 2 },
  { label: "Como nos conheceu?", type: "select", options: { values: ["Instagram", "Indicação", "Moro perto", "Outro"] }, required: true, pos: 3 }
]

fields.each do |field|
  FormField.find_or_create_by!(form: form, label: field[:label]) do |ff|
    ff.label_type = field[:type]
    ff.required = field[:required]
    ff.position = field[:pos]
    ff.options = field[:options] if field[:options]
  end
end

puts "--- Seeding Completed Successfully ---"
