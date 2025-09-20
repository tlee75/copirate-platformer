extends GameItem
class_name SwordItem

func action(user):
	print("Sword attack by %s" % user.name)
	user.is_trigger_action = true
	user.get_node("AnimatedSprite2D").play("attack")
	
