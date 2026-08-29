class_name StairStepper

static func try_step_up(body: CharacterBody3D, max_step_height: float = 0.3, forward_check_dist: float = 0.2, landing_probe_dist: float = 0.25) -> void:
	if not body.is_on_floor():
		return
	var horizontal := Vector3(body.velocity.x, 0.0, body.velocity.z)
	if horizontal.length() < 0.05:
		return
	var direction := horizontal.normalized()
	var space_state := body.get_world_3d().direct_space_state

	var floor_probe_from := body.global_position + Vector3(0.0, 0.5, 0.0)
	var floor_probe_to := body.global_position + Vector3(0.0, -3.0, 0.0)
	var floor_query := PhysicsRayQueryParameters3D.create(floor_probe_from, floor_probe_to)
	floor_query.exclude = [body.get_rid()]
	var floor_result := space_state.intersect_ray(floor_query)
	if not floor_result:
		print("stair_stepper: no floor found")
		return
	var floor_y: float = floor_result.position.y

	var foot_origin := Vector3(body.global_position.x, floor_y + 0.05, body.global_position.z)
	var foot_query := PhysicsRayQueryParameters3D.create(foot_origin, foot_origin + direction * forward_check_dist)
	foot_query.exclude = [body.get_rid()]
	foot_query.hit_from_inside = true
	if not space_state.intersect_ray(foot_query):
		return
	var head_origin := Vector3(body.global_position.x, floor_y + max_step_height + 0.02, body.global_position.z)
	var head_query := PhysicsRayQueryParameters3D.create(head_origin, head_origin + direction * forward_check_dist)
	head_query.exclude = [body.get_rid()]
	head_query.hit_from_inside = true
	if space_state.intersect_ray(head_query):
		return
	var probe_from := head_origin + direction * landing_probe_dist
	var probe_query := PhysicsRayQueryParameters3D.create(probe_from, probe_from + Vector3(0.0, -(max_step_height + 0.1), 0.0))
	probe_query.exclude = [body.get_rid()]
	var probe_result := space_state.intersect_ray(probe_query)
	if not probe_result:
		return
	var step_y: float = probe_result.position.y - floor_y
	if step_y <= 0.0 or step_y > max_step_height + 0.02:
		return
	body.global_position += direction * (forward_check_dist * 0.5)
	body.global_position.y += step_y + 0.02
	body.velocity.y = 0.0
