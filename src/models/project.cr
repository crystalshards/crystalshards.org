class Project
  include Clear::Model
  include Orion::Cache::Keyable

  define_cache_key self.class.name, id, updated_at

  primary_key
  column provider : Provider
  column uri : String
  column homepage : String?
  column description : String?
  column api_id : String?
  column watcher_count : Int32?
  column star_count : Int32?
  column pull_request_count : Int32?
  column issue_count : Int32?
  column mirror_type : MirrorType?
  column tags : Array(String), presence: false
  column pushed_at : Time?

  timestamps

  belongs_to mirrored : Project, foreign_key: "mirrored_id", key_type: Int64?
  has_many mirrors : Project, foreign_key: "mirrored_id"
  has_many dependents : ShardDependency, foreign_key: "dependency_id"
  has_many shards : Shard

  def dependent_count
    dependents
      .join("shards") { shards.id == shard_dependencies.parent_id }
      .distinct("shards.project_id")
      .count
  end

  def url
    "#{provider.base_url}#{uri}"
  end

  def last_pushed_at_string : String
    return "Unknown" unless (pushed_at = self.pushed_at)
    span = Time.utc - pushed_at
    if span.total_days >= 1
      "#{span.total_days.to_i}d ago"
    elsif span.total_hours >= 1
      "#{span.total_hours.to_i}h ago"
    elsif span.total_minutes >= 1
      "#{span.total_minutes.to_i}m ago"
    else
      "#{span.total_seconds.to_i}s ago"
    end
  end

  def clone_url
    case provider
    when "github", "gitlab", "bitbucket"
      "#{url}.git"
    when "git"
      uri
    end
  end
end
