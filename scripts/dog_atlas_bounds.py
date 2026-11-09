"""Measure sprite silhouettes without modifying source pixels."""


def subject_bounds(image, cell, padding=2, horizontal_overflow=0):
    """Measure the main silhouette, excluding fragments from neighboring poses."""
    x0,y0,x1,y1 = cell
    search_left = max(0,x0-horizontal_overflow)
    search_right = min(image.width,x1+horizontal_overflow)
    alpha = image.crop((search_left,y0,search_right,y1)).getchannel('A')
    width, height = alpha.size
    remaining = bytearray(1 if value >= 194 else 0 for value in alpha.tobytes())
    largest, result = 0, None
    for seed in range(len(remaining)):
        if not remaining[seed]:
            continue
        remaining[seed] = 0
        stack = [seed]
        count = 0
        left, right = width, 0
        top, bottom = height, 0
        while stack:
            index = stack.pop()
            x, y = index % width, index // width
            count += 1
            left, right = min(left,x), max(right,x+1)
            top, bottom = min(top,y), max(bottom,y+1)
            for ny in range(max(0,y-1),min(height,y+2)):
                for nx in range(max(0,x-1),min(width,x+2)):
                    neighbor = ny*width+nx
                    if remaining[neighbor]:
                        remaining[neighbor] = 0
                        stack.append(neighbor)
        center = search_left+(left+right)*.5
        if count > largest and x0 <= center < x1:
            largest, result = count, (left,top,right,bottom)
    if result is None:
        raise ValueError(f'Empty sprite cell: {cell}')
    return (search_left-x0+max(0,result[0]-padding),max(0,result[1]-padding),
            search_left-x0+min(width,result[2]+padding),min(height,result[3]+padding))
