class ShardDependency
  include Clear::Model
  include Orion::Cache::Keyable

  define_cache_key self.class.name, id, updated_at

  primary_key
  column name : String
  column ref_type : RefType?
  column ref_name : String?
  column requirement_operator : Manifest::Shard::Dependency::Requirement::Operator?
  column requirement_version : String?
  column development : Bool

  timestamps

  belongs_to shard : Shard, foreign_key: "parent_id"
  belongs_to dependency : Project, foreign_key: "dependency_id"

  def self.associate(parent : Shard, name : String, dependency : Manifest::Shard::Dependency::Provider, development : Bool = false)
    project = Project.query.find_or_create({provider: dependency.provider, uri: dependency.uri}) { }
    query.find_or_create({parent_id: parent.id, name: name, dependency_id: project.id, development: false}) do |dep|
      if (ref_type = dependency.ref_type)
        dep.ref_type = RefType.from_string(ref_type)
      end
      dep.requirement_operator = dependency.version.try(&.operator)
      dep.requirement_version = dependency.version.try(&.version)
      dep.ref_name = dependency.ref_name
      dep.development = development
    end
  end

  scope :production do
    where { shard_dependencies.development == false }
  end

  scope :development do
    where { shard_dependencies.development == true }
  end

  def requirement_string
    case ref_type
    when RefType::Commit
      "#{ref_type.to_s}: #{ref_name.try(&.chars.first(7).join)}"
    when .nil?, RefType::Version
      version_requirement_string
    else
      "#{ref_type.to_s}: #{ref_name}"
    end
  end

  private def version_requirement_string
    op = requirement_operator.try(&.operator)
    op ||= "=" if requirement_version
    v = requirement_version
    v ||= "*" unless op
    [op, v].compact.join(" ")
  end
end
