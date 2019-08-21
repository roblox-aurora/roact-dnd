function pointsIntersect(instPos, instEndPos, intersectPos, intersectEndPos)
	return (
		instEndPos.X 	> 	intersectPos.X 		and
		instEndPos.Y 	> 	intersectPos.Y 		and
		instPos.X 		< 	intersectEndPos.X 	and
		instPos.Y 		< 	intersectEndPos.Y
	);
end

return {
	pointsIntersect = pointsIntersect
}