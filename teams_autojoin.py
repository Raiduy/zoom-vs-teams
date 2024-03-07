import sys
import pyautogui

def teams_routine(tab_num):
    
    # Bring Teams to the front
    with pyautogui.hold('win'):
        pyautogui.press(str(tab_num))
        pyautogui.sleep(5)


    # Join the meeting
    pyautogui.press('tab')
    pyautogui.press('tab')
    pyautogui.press('enter')

if __name__ == '__main__':
    teams_routine(sys.argv[1])