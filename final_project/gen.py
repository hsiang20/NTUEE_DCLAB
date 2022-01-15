import random

plate_amount = 300
monster_amount = 10

def write_list(file, lis):
    with open(file, 'w') as f:
        for val in lis:
            f.write(hex(val).upper()[2:])
            f.write('\n')

# with open('./src/plate_pos_x.mem', 'w') as fx:
#     last_x = 320
#     for i in range(plate_amount):
#         while True:
#             x = random.randrange(64, 512)
#             if abs(x - last_x) <= 350:
#                 last_x = x
#                 break
#         print(x)
#         fx.write(hex(x).upper()[2:])
#         fx.write('\n')
# with open('./src/plate_pos_y.mem', 'w') as fy:
#     y = 100
#     for i in range(plate_amount):
#         print(y)
#         fy.write(hex(y).upper()[2:])
#         fy.write('\n')
#         y += random.randrange(30, 80)
      
plate_x = []
plate_y = []  
monster1_x = []
monster1_y = []
monster2_x = []
monster2_y = []  

# y
y = 100
for i in range(plate_amount):
    plate_y.append(y)
    y += random.randrange(30, 80)
     
# monster1 x, y
for i in range(monster_amount):
    while True:
        sx = random.randrange(0, 576)
        sy = random.randrange(1500, y - 200)
        for j in range(len(monster1_x)):
            if abs(sx - monster1_x[j]) < 64 and abs(sy - monster1_y[j]) < 64:
                continue
        monster1_x.append(sx)
        monster1_y.append(sy)
        break
    
# monster2 x, y
for i in range(monster_amount):
    while True:
        sx = random.randrange(0, 576)
        sy = random.randrange(3000, y - 200)
        for j in range(len(monster2_x)):
            if abs(sx - monster2_x[j]) < 64 and abs(sy - monster2_y[j]) < 96:
                continue
        for j in range(len(monster1_x)):
            if abs(sx - monster1_x[j]) < 64 and abs(sy - monster1_y[j]) < 96:
                continue
        monster2_x.append(sx)
        monster2_y.append(sy)
        break
    
for i in range(plate_amount):
    while True:
        x = random.randrange(64, 512)
        for j in range(monster_amount):
            if abs(x - monster1_x[j]) < 64 and abs(plate_y[i] - monster1_y[j]) < 16:
                continue
            if abs(x - monster2_x[j]) < 64 and abs(plate_y[i] - monster2_y[j]) < 16:
                continue
        plate_x.append(x)
        break

print(monster1_x, monster1_y)   
print(monster2_x, monster2_y)    
print(plate_x)
print(plate_y) 

write_list('./src/plate_pos_x.mem', plate_x)
write_list('./src/plate_pos_y.mem', plate_y)
write_list('./src/monster_pos_x.mem', monster1_x)
write_list('./src/monster_pos_y.mem', monster1_y)
write_list('./src/monster2_pos_x.mem', monster2_x)
write_list('./src/monster2_pos_y.mem', monster2_y)

# with open('./src/monster_pos_x.mem', 'w') as fmx:
#     with open('./src/monster_pos_y.mem', 'w') as fmy:
#         dao
