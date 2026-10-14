class_name SkillTreeData
extends Resource
## Der Fähigkeitenbaum einer Figur: Äste in Anzeige-Reihenfolge und alle Fähigkeiten.

@export var branches: Array[String] = []
@export var skills: Array[SkillData] = []


func get_skills_in_branch(branch: String) -> Array[SkillData]:
	var result: Array[SkillData] = []
	for skill in skills:
		if skill.branch == branch:
			result.append(skill)
	return result


func get_skill(id: StringName) -> SkillData:
	for skill in skills:
		if skill.id == id:
			return skill
	return null
