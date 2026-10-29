namespace :access_profiles do
  desc "Provisiona perfis e migra vínculos sem duplicar ou sobrescrever personalizações"
  task provision: :environment do
    Church.find_each do |church|
      Access::MigrateService.call(church: church)
      puts "#{church.id}: #{church.name} — #{church.access_profiles.count} perfis"
      warn "Igreja #{church.id}: sem administrador ativo; regularização necessária" if Access::Integrity.administrators(church).empty?
    end
  end
end
