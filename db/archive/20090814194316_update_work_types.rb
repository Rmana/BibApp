class BookEdited < Work
end

class JournalEdited < Work
end

class SoundRecording < Work
end

class Video < Work
end

class UpdateWorkTypes < ActiveRecord::Migration
  def self.up

    say_with_time "Updating work subtypes..." do
      works = Work.find(:all,
      :conditions => ['type = ? or type = ? or type = ? or type = ?', 'BookEdited', 'JournalEdited', 'SoundRecording', 'Video'])
      ri_a = Array.new
      works.each do |w|
        if w.type.to_s == "BookEdited"
          w.update_type_and_save_without_callbacks('BookWhole')
          say "Work #{w.id} changed from Book (Edited) to Book (Whole)!", true
        end
        if w.type.to_s == "JournalEdited"
          w.update_type_and_save_without_callbacks('JournalWhole')
          say "Work #{w.id} changed from Journal (Edited) to Journal (Whole)!", true
        end
        if w.type.to_s == "SoundRecording"
          w.update_type_and_save_without_callbacks('RecordingSound')
          say "Work #{w.id} changed from Sound Recording to Recording (Sound)!", true
        end
        if w.type.to_s == "Video"
          w.update_type_and_save_without_callbacks('RecordingMovingImage')
          say "Work #{w.id} changed from Video to Recording (Moving Image)!", true
        end
        ri_a << w
      end
      Index.batch_update_solr(ri_a)
    end

  end

  def self.down
    # No turning back.
    raise ActiveRecord::IrreversibleMigration, "Sorry, you can't migrate down."
  end
end
